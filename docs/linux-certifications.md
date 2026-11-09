# Linux certification labs

| Profile | Guest | SSH address | Resources |
| --- | --- | --- | --- |
| LFCS | AlmaLinux 10.2, DNF/RPM and enforcing SELinux | `vboxuser@192.168.101.40` | 2 CPUs, 2 GB |
| LFCA | Ubuntu 24.04 LTS, APT/dpkg and AppArmor | `vboxuser@192.168.101.41` | 2 CPUs, 2 GB |

LFCS is a practical administration exam. LFCA is a
[multiple-choice certification](https://training.linuxfoundation.org/certification/certified-it-associate/);
its Ubuntu guest supports learning the concepts. Passing an environment check
does not demonstrate mastery of either syllabus.

## Prepare and connect

Activate `.venv` and run commands from the repository directory on WSL or macOS.
Create only the selected Linux guest, preserving the other Linux guest:

```bash
ansible-playbook -i inventories/lfcs.ini setup/hosts/linux_vms.yml
ansible-playbook -i inventories/lfcs.ini setup/certification_lab.yml \
  -e @profiles/certifications/lfcs.yml
```

For LFCA, replace both `lfcs` paths with `lfca`. On Windows, use this WSL command
for the VM-creation step if the terminal lacks Hyper-V management privileges:

```bash
pwsh.exe -NoProfile -File "$(wslpath -w scripts/hyperv_setup.ps1)" \
  -StartLab -WslDistribution "$WSL_DISTRO_NAME" -LinuxUser "$(id -un)" \
  -LabRepository "$PWD" -Inventory inventories/lfca.ini \
  -LabPlaybook setup/hosts/linux_vms.yml
```

Add `-RebuildLinuxVm` to replace only that selected guest and its disk. On macOS,
pass `-e rebuild_linux_vm=true` to the VM playbook. Afterwards, run the matching
`setup/certification_lab.yml` command to configure and verify the new OS.
`setup/fresh_certification.yml` has broader scope: it removes all managed VMs.

Choose one SSH command on the controller:

```bash
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.40  # LFCS
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.41  # LFCA
```

Use `sudo -i` inside the guest for administration exercises. The account and
key remain the same across rebuilds; provisioning refreshes trusted host keys.
LFCS virtualization exercises require nested KVM. Vagrant enables its host
extensions for Hyper-V and for x86 VirtualBox hosts. See the
[VirtualBox nested virtualization requirements](https://docs.oracle.com/en/virtualization/virtualbox/7.1/user/AdvancedTopics.html).
On a host/provider without nested KVM support, use another capable Linux host
for that objective; the KVM readiness check will fail rather than report it covered.

## LFCS: complete topic and tool map

The following map follows the
[official objectives](https://training.linuxfoundation.org/certification/linux-foundation-certified-sysadmin-lfcs/)
and the [LFCS GitHub guide](https://github.com/Zeukkari/lfcs-test-lab/blob/master/docs/README.md)
(repository created 3 November 2026). Follow its domain notes and original
practice scenarios using this lab's addresses and AlmaLinux package names.
The package declaration is `setup/vars/linux.yml`; `tests/tasks/lfcs_tools.yml`
checks that the commands are available. Servers such as LDAP, Samba, NFS,
iSCSI targets and HAProxy are installed for exercises, without creating or
starting application instances automatically.

### Operations and deployment — 25%

| Objective area | Prepared tools | Hands-on goal |
| --- | --- | --- |
| Kernel settings | `sysctl`, `modprobe`, `/etc/sysctl.d` | Change a namespaced setting, then compare temporary and persistent configuration. |
| Processes and services | `ps`, `top`, `kill`, `systemctl`, `journalctl` | Diagnose a failing unit and prove that its process recovers. |
| Job scheduling | `crontab`, `at`, systemd timers | Schedule a marker write, inspect execution, remove the job. |
| Packages and repositories | `dnf`, `rpm`, DNF plugins | Query ownership, validate files, inspect and repair a test repository definition. |
| Boot and filesystem recovery | GRUB tools, `dracut`, `fsck`, `xfs_repair`, `sos` | Recover a disposable filesystem and practise VM rescue through its console. |
| Virtual machines | libvirt, `virsh`, `virt-install`, QEMU/KVM | Create a small nested guest, inspect its network/disk, stop and remove it. |
| Containers | Podman | Run with limits and mounts, inspect, stop, recreate and clean up. |
| SELinux | `getenforce`, `semanage`, `restorecon`, `chcon` | Diagnose a denial and correct the persistent label while enforcement stays enabled. |

### Networking — 25%

| Objective area | Prepared tools | Hands-on goal |
| --- | --- | --- |
| Addressing and name resolution | `nmcli`, `ip`, `getent`, `dig` | Configure test IPv4/IPv6 addresses and resolve a deliberately broken name. |
| Clock synchronization | chrony, `timedatectl` | Inspect sources, tracking and the configured timezone. |
| Network diagnosis | `ss`, `tcpdump`, `mtr`, `traceroute`, `ethtool`, `iperf3` | Separate listener, route, firewall and DNS failures. |
| SSH | OpenSSH server/client | Create a separate practice key, validate `sshd -t`, test its login. |
| Filtering and translation | firewalld, nftables, `iptables-nft` | Permit a test port, add forwarding/NAT rules, inspect counters. |
| Routes | `ip route`, NetworkManager | Add and remove a test route; compare runtime and persistent state. |
| Bridges and bonds | `ip link`, `bridge`, `nmcli` | Build devices in an isolated network namespace before configuring real interfaces. |
| Proxying and balancing | HAProxy, httpd, `curl` | Route to two disposable backends, stop one, verify the remaining backend. |

### Storage — 20%

| Objective area | Prepared tools | Hands-on goal |
| --- | --- | --- |
| Logical volumes | LVM2 | Create a PV/VG/LV, grow it and verify retained data. |
| Mounts and virtual filesystems | `mount`, `findmnt`, `lsblk`, `/proc`, `/sys` | Diagnose a mount and correct its own fstab entry. |
| Filesystem lifecycle | `parted`, `fdisk`, ext4/XFS tools, `cryptsetup`, `mdadm` | Partition a scratch device; create, inspect, resize and recover test storage. |
| Remote files and block storage | NFS, Samba/CIFS, `iscsiadm`, `targetcli` | Export test data or a scratch target; connect and verify writes through a client. |
| Swap | `mkswap`, `swapon`, `swapoff` | Create temporary swap, verify activation, deactivate and remove it. |
| Automounting | autofs | Configure a test map, trigger a mount, inspect expiry and logs. |
| Storage performance | `iostat`, `vmstat`, `df`, `du` | Identify capacity versus latency problems using measured output. |

### Essential commands — 20%

| Objective area | Prepared tools | Hands-on goal |
| --- | --- | --- |
| Git | `git` | Commit, branch, merge and restore a disposable repository. |
| Service configuration | systemd, httpd | Build and debug a practice unit and validate its configuration. |
| Performance diagnosis | `top`, `vmstat`, `iostat`, `strace`, `perf`, `lsof` | Identify a constrained or failing process from evidence. |
| Service constraints | `prlimit`, `ulimit`, systemd properties | Set a limit and prove the process actually runs under it. |
| Disk usage | `df`, `du`, `find`, `lsof` | Locate used space, including a deleted file held open by a process. |
| TLS | OpenSSL, CA-store tools | Issue a test certificate, verify its trust and hostname, diagnose a mismatch. |

### Users and groups — 10%

| Objective area | Prepared tools | Hands-on goal |
| --- | --- | --- |
| Local identities | `useradd`, `usermod`, `groupadd`, `chage`, sudo | Create and remove an isolated account with a limited administrative task. |
| Shell environments | Bash, `/etc/profile.d`, user startup files | Explain login versus interactive shells and test an environment change. |
| User limits | PAM limits, `ulimit`, `prlimit` | Apply a limit and verify it in a new login session. |
| ACLs | `setfacl`, `getfacl` | Prove deny → allow → revoke for an unprivileged account. |
| Directory identities | SSSD, authselect, LDAP clients, 389 Directory Server tools | Create a disposable directory instance, query entries, configure a client and verify `getent` resolution. |

## LFCS practice sequence

Work one exercise at a time. Record the command that proves success, then repeat
without copying the implementation. Use a separate shell for an administrative
exercise that changes login or firewall configuration.

1. **Storage and recovery:** attach a scratch image, create test storage, write
   a marker, grow the filesystem and remount it. Verify the marker and capacity.
   Break only the exercise's mount configuration, diagnose it and restore it.
2. **Identity and confinement:** create a temporary user, demonstrate ACL access,
   revoke it, then perform the SELinux HTTP-label denial/recovery exercise.
   Prove that ordinary permissions alone do not explain the SELinux denial.
3. **Scheduling and limits:** create a timer-driven service with a memory limit.
   Confirm its output, inspect `systemctl show`, and remove its timer and unit.
4. **Networking:** enter `unshare --net bash`, create dummy, bridge and bond
   devices, add IPv4/IPv6 addresses, a route and a NAT rule. Inspect each result;
   exit the shell to discard the namespace. Management networking stays outside it.
5. **Services and TLS:** configure two test HTTP backends and an HAProxy frontend.
   Verify traffic distribution and failover. Create a test CA and server certificate;
   verify the correct hostname and reject the wrong hostname.
6. **Remote storage:** use a scratch path for an NFS or SMB export, or a scratch
   image as an iSCSI target. Connect with a separate client, write/read a marker,
   then disconnect and remove only the exercise's export or target.
7. **Directory authentication:** use `dscreate interactive` for a disposable LDAP
   instance; practise `ldapsearch` before changing NSS/PAM. Verify client identity
   resolution, then restore the prior authentication configuration and remove the instance.
8. **Containers and virtual machines:** create limited workloads, inspect their
   storage/networking, recover from a deliberate configuration error and clean up.
   `virsh --connect qemu:///system domcapabilities --virttype kvm` verifies KVM support.

For a separate storage/directory client, start the Ubuntu LFCA guest with the
targeted Linux VM workflow above, preserving LFCS. Select its optional client
packages through the same setup entry point:

```bash
ansible-playbook -i inventories/lfca.ini setup/certification_lab.yml \
  -e @profiles/certifications/lfca.yml -e linux_remote_client=true
```

This adds NFS, SMB/CIFS, iSCSI and LDAP clients for the two-guest exercise.
The ordinary LFCA profile retains its smaller fundamentals package selection.

### Scratch storage

The playbook creates three initially sparse 2 GB files beneath
`/var/lib/kubeadm-certifications/lfcs/disks/`. Re-running setup preserves them.
They allocate host space only as exercises write to them. As root inside LFCS:

```bash
practice_loop=$(losetup --find --show --partscan /var/lib/kubeadm-certifications/lfcs/disks/disk1.img)
printf '%s\n' "$practice_loop"
lsblk "$practice_loop"
```

Use the printed loop device for the exercise. After unmounting its filesystems
and deactivating any test LVM/RAID devices, detach it with
`losetup --detach "$practice_loop"`. Loop attachments are temporary; a reboot
requires reattaching them. Use an fstab loop mount for a filesystem image, or an
explicit attachment service when practising boot persistence with partitioned images.

## LFCA: study with Ubuntu

Use the [official LFCA objectives](https://training.linuxfoundation.org/certification/certified-it-associate/)
for the complete knowledge syllabus. Practise the following alongside reading:

| Domain | Weight | Learning activity |
| --- | --- | --- |
| Linux fundamentals | 16% | Files, shell commands, permissions, processes and Ubuntu package queries |
| System administration | 30% | APT/dpkg, Apache2, systemd, logs, UFW, DNS and recovery concepts |
| Cloud concepts | 18% | Compare service models, availability designs, networking and cost choices |
| Security | 14% | Users, permissions, SSH, AppArmor, sensitive-data handling and compliance concepts |
| DevOps | 12% | Git workflow, container lifecycle and delivery concepts |
| IT project management | 10% | Requirements, risk, application architecture and open-source licensing |

The automated LFCA checks validate the Ubuntu learning environment. They do not
score the cloud, security, architecture or project-management knowledge domains.

## Verify and repeat

```bash
ansible-playbook -i inventories/lfcs.ini tests/linux.yml -e @profiles/certifications/lfcs.yml
ansible-playbook -i inventories/lfca.ini tests/linux.yml -e @profiles/certifications/lfca.yml
```

LFCS checks include real confinement, storage growth, ACL, container, KVM,
scheduled-service, Git/TLS and isolated-network exercises. Tool availability
checks cover the full map; they do not execute every manual scenario above.
Reports are private files under `artifacts/certification-results/`, with the
actual OS, VM identity and executed check names.

Plain Bash is the baseline. LFCS includes Bash completion and tmux for everyday
practice; shell frameworks and fzf remain optional. Practise without custom
shortcuts as well. Reconcile the selected profile to restore its managed baseline;
rebuild only its VM when a clean OS is required.

## Stop, destroy and reclaim space

To finish with both Linux labs, stop and destroy their VMs and writable disks,
then remove regenerable lab downloads and unused base boxes:

```bash
ansible-playbook -i inventories/lfcs.ini setup/maintenance/linux_cleanup.yml
```

On WSL, use the Windows launch option for the same cleanup playbook:

```bash
pwsh.exe -NoProfile -File "$(wslpath -w scripts/hyperv_setup.ps1)" \
  -StartLab -WslDistribution "$WSL_DISTRO_NAME" -LinuxUser "$(id -un)" \
  -LabRepository "$PWD" -Inventory inventories/lfcs.ini \
  -LabPlaybook setup/maintenance/linux_cleanup.yml
```

This preserves the shared SSH key and private verification reports. It refuses
to force removal of a base box still in use. Recreating a lab downloads its
removed base box again. To remove completed Homebrew downloads and the pip
download cache without uninstalling tools or changing `.venv`, run:

```bash
ansible-playbook setup/maintenance/controller_cleanup.yml
```

On WSL with filesystem discard support, add
`-e controller_trim_unused_space=true` to issue TRIM for already free blocks.
The playbook invokes the current WSL distribution's root account for that single
filesystem operation; it leaves files, installed tools and the running WSL session in place.
