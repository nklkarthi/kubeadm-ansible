[CmdletBinding()]
param(
    [string]$SwitchName = 'kubeadm-lab',
    [string]$BridgeDescription = 'Realtek PCIe GbE Family Controller #3',
    [string]$WindowsUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name,
    [switch]$StartLab,
    [string]$WslDistribution,
    [string]$LinuxUser,
    [string]$LabRepository,
    [ValidatePattern('^(setup/inventory|inventories/[a-zA-Z0-9_.-]+\.(ini|example))$')]
    [string]$Inventory = 'setup/inventory',
    [ValidatePattern('^setup/[a-zA-Z0-9_/-]+\.yml$')]
    [string]$LabPlaybook
)
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'),
                   '-SwitchName', ('"' + $SwitchName + '"'), '-BridgeDescription', ('"' + $BridgeDescription + '"'),
                   '-WindowsUser', ('"' + $WindowsUser + '"'))
    if ($StartLab) {
        $arguments += @('-StartLab', '-WslDistribution', ('"' + $WslDistribution + '"'),
                        '-LinuxUser', ('"' + $LinuxUser + '"'), '-LabRepository', ('"' + $LabRepository + '"'),
                        '-Inventory', ('"' + $Inventory + '"'))
        if ($LabPlaybook) { $arguments += @('-LabPlaybook', ('"' + $LabPlaybook + '"')) }
    }
    $process = Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $process.ExitCode
}
$reportDirectory = Join-Path $env:LOCALAPPDATA 'Temp\kubeadm-hyperv'
[void](New-Item -ItemType Directory -Force -Path $reportDirectory)
$reportFile = Join-Path $reportDirectory 'status.json'
Start-Transcript -Path (Join-Path $reportDirectory 'setup.log') -Force
try {
    $restartNeeded = $false
    if (-not (Get-Service vmms -ErrorAction SilentlyContinue)) {
        $dism = Join-Path $env:SystemRoot 'System32\dism.exe'
        $feature = & $dism /Online /Get-FeatureInfo /FeatureName:Microsoft-Hyper-V-All /English
        if ($LASTEXITCODE -ne 0) { throw "Unable to query Hyper-V: DISM exit $LASTEXITCODE" }
        if (($feature -join "`n") -notmatch '(?m)^State\s*:\s*Enabled\s*$') {
            & $dism /Online /Enable-Feature /FeatureName:Microsoft-Hyper-V-All /All /NoRestart /English | Out-Host
            if ($LASTEXITCODE -notin @(0, 3010)) { throw "Unable to enable Hyper-V: DISM exit $LASTEXITCODE" }
            $restartNeeded = $LASTEXITCODE -eq 3010
        }
    }
    try {
        Start-Service vmms
        Import-Module Hyper-V
        [void](Get-VMHost)
    } catch {
        if ($restartNeeded) {
            @{Status='restart-required'; RestartNeeded=$true; Switch=$SwitchName} | ConvertTo-Json | Set-Content $reportFile
            exit 3010
        }
        throw
    }
    $administrators = Get-LocalGroup -SID 'S-1-5-32-578'
    $userSid = [Security.Principal.NTAccount]::new($WindowsUser).Translate([Security.Principal.SecurityIdentifier]).Value
    if ($userSid -notin @(Get-LocalGroupMember -Group $administrators.Name | ForEach-Object {$_.SID.Value})) {
        Add-LocalGroupMember -Group $administrators.Name -Member $WindowsUser
    }
    $existingSwitch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if (-not $existingSwitch) {
        $adapter = @(Get-NetAdapter -Physical | Where-Object {$_.InterfaceDescription -eq $BridgeDescription -and $_.Status -eq 'Up'})
        if ($adapter.Count -ne 1) { throw 'Select one connected physical adapter for the lab switch.' }
        $existingSwitch = New-VMSwitch -Name $SwitchName -NetAdapterName $adapter[0].Name -AllowManagementOS $true
    }
    if ($existingSwitch.SwitchType -ne 'External') { throw 'The selected lab switch must connect to the physical LAN.' }
    @{Status='ready'; RestartNeeded=$restartNeeded; Switch=$existingSwitch.Name; WindowsUser=$WindowsUser} | ConvertTo-Json | Set-Content $reportFile
    if ($StartLab) {
        if (-not $WslDistribution -or -not $LinuxUser -or -not $LabRepository.StartsWith('/')) {
            throw 'StartLab requires WslDistribution, LinuxUser and an absolute Linux LabRepository path.'
        }
        $ansible = $LabRepository.TrimEnd('/') + '/.venv/bin/ansible-playbook'
        $wslPath = & wsl.exe --distribution $WslDistribution --user $LinuxUser --exec /usr/bin/printenv PATH
        if ($LASTEXITCODE -ne 0) { throw 'Unable to read the WSL controller PATH.' }
        $controllerPath = $LabRepository.TrimEnd('/') + '/.tools/bin:/home/linuxbrew/.linuxbrew/bin:' + ($wslPath -join '').Trim()
        $playbooks = if ($LabPlaybook) { @($LabPlaybook) } else { @('setup/hosts/vagrant.yml', 'tests/local_vms.yml', 'setup/kube_cluster.yml') }
        foreach ($playbook in $playbooks) {
            $playbookLog = Join-Path $reportDirectory ((Split-Path $playbook -Leaf) + '.log')
            & wsl.exe --distribution $WslDistribution --user $LinuxUser --cd $LabRepository --exec /usr/bin/env `
                "PATH=$controllerPath" ANSIBLE_LOCAL_TEMP=/tmp/ansible-local PYTHONUNBUFFERED=1 $ansible $playbook -i $Inventory `
                -e vagrant_provider=hyperv -e controller_image_cache=true -e download_via_controller=true 2>&1 |
                Tee-Object -FilePath $playbookLog
            if ($LASTEXITCODE -ne 0) { throw "Lab playbook $playbook failed with exit $LASTEXITCODE" }
        }
    }
} catch {
    @{Status='failed'; Error=$_.Exception.Message} | ConvertTo-Json | Set-Content $reportFile
    throw
} finally { Stop-Transcript }
