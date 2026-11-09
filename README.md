# kubeadm-ansible

Build certification learning environments with Ansible from WSL or macOS.
Choose a certification profile to install its prerequisites, prepare its clients,
and verify the resulting lab. Use local Vagrant VMs at home or the Pluralsight
inventory while travelling.

## Choose your certification

Start with the [certification guide](docs/certifications.md): it lists every
supported certification, its profile, installation order and practice scope.
The [Linux guide](docs/linux-certifications.md) maps every LFCS syllabus objective
to installed tools and practice material, and explains LFCA's knowledge-based study.
Use the [practical lab guide](docs/practical-labs.md) for detailed LFCS, CKA, CKS,
CNPE and CKAD task, verification, failure-recovery and cleanup workflows.
All five are performance-based certifications that require hands-on practice.

| Learning environment | Inventory | Profile | Guest OS |
| --- | --- | --- | --- |
| Kubernetes certification | `setup/inventory` | `profiles/certifications/CERT.yml` | Ubuntu 24.04 LTS |
| LFCS administration | `inventories/lfcs.ini` | `profiles/certifications/lfcs.yml` | AlmaLinux 10.2 |
| LFCA fundamentals | `inventories/lfca.ini` | `profiles/certifications/lfca.yml` | Ubuntu 24.04 LTS |

Use this study cycle: **select a profile → create the lab → connect → practise
the guide's exercises → verify → reset when a fresh environment is needed**.
The automated checks verify the environment and representative workloads;
they are not exam simulators or a substitute for completing the exercises.

## Requirements

- Controller: macOS or WSL, Python 3.12–3.14, Ansible, and `kubectl`.
- Kubernetes guests: Ubuntu 22.04 or newer, unique hostnames/MACs, SSH access, and sudo.
- Home VM defaults: Ubuntu 24.04 LTS, 2 CPUs and 4 GB RAM per Kubernetes node.
- Guest addresses must be stable and reachable from each other and the controller.
- Pod and service networks must not overlap the guest networks.
- Homebrew on the controller manages Helm, crane, Vagrant and selected certification CLIs.
- The controller-tools playbook installs missing tools and verifies their tested version pins.
- Optional: sign in with `gh auth login` on the controller to use authenticated,
  checksummed GitHub release downloads. GitHub credentials stay on the controller.
- Home VM management uses Vagrant and Homebrew, with native Hyper-V on Windows
  or VirtualBox on macOS.

[Kubeadm's minimum](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)
is 2 GB RAM per machine and 2 CPUs for each control plane. The home defaults
provide additional room for certification workloads; 4 GB is not a kubeadm
requirement. Workers keep 2 CPUs as a lab choice. Review workload requests,
available memory, memory pressure and eviction events before reducing VM RAM.
CNPE selects a 6 GB control plane for its larger collection of Kubernetes APIs;
its workers retain the 4 GB default.
Pass `-e @profiles/certifications/cnpe.yml` when starting these VMs through
`setup/hosts/vagrant.yml` outside the certification entry point.
The dedicated LFCS and LFCA guests use 2 CPUs and 2 GB each without Kubernetes.

Install the controller tools in a virtual environment:

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
```

Ubuntu controllers need the matching `python3.14-venv` package for the standard
`venv` command. Activate `.venv` before running validation or deployment.

Certification profiles prepare their clients on the WSL or macOS controller.
To prepare clients separately from VM creation, select the same profile:

```bash
ansible-playbook -i setup/inventory setup/hosts/controller_tools.yml \
  -e @profiles/certifications/capa.yml
```

Homebrew manages the Kubernetes and project CLIs. Backstage development uses
Homebrew's Node 24 and npm-managed Corepack to select Yarn. Clients are shared
between disposable labs and verified against the release pins. See the
[client selection table](docs/certifications.md#controller-clients).

## Repository layout

Inventories select **where** to run, profiles select **what** to prepare, playbooks
define **how**, and tests verify the deployed environment.

| File or directory | Purpose |
| --- | --- |
| `ansible.cfg` | Default inventory, SSH and Ansible behaviour |
| `Vagrantfile` | VM operating systems, addresses, CPUs, RAM and first-boot provisioning |
| `setup/inventory`, `inventories/` | Host addresses, roles, SSH account and expected guest OS |
| `profiles/certifications/` | Certification component selection and study topics |
| `setup/fresh_certification.yml` | Delete the previous managed VMs, create fresh guests, then install and test the selected certification |
| `setup/certification_lab.yml` | Configure an existing environment; selects the Linux or Kubernetes workflow |
| `setup/validate_profile.yml` | Check profile, inventory, component dependencies and topology locally before provisioning |
| `setup/linux_certification.yml` | Linux tools, services and functional checks |
| `setup/kubernetes_certification.yml` | Kubernetes, selected add-ons, client initialization and certification checks |
| `setup/kube_cluster.yml`, `setup/fresh_cluster.yml` | Configure the base cluster, or recreate its VMs first |
| `setup/hosts/` | VM lifecycle, guest preparation and controller clients |
| `setup/cluster/`, `setup/addons/`, `setup/security/` | Kubernetes bootstrap and optional workload/security installers |
| `setup/tasks/`, `setup/templates/` | Shared configuration tasks and resource templates |
| `setup/vars/common.yml`, `setup/vars/linux.yml` | Tool versions and shared settings; Linux packages, services and syllabus commands |
| `setup/maintenance/` | Cluster status, reset, recovery and expendable-cache cleanup |
| `tests/linux.yml`, `tests/certification.yml`, `tests/tasks/` | Live environment checks and certification-specific scenarios |
| `scripts/validate_playbooks.sh` | Syntax, lint and local semantic validation |
| `scripts/vagrant.sh`, `scripts/hyperv_setup.ps1` | VM command wrapper and Windows VM-lifecycle launch option |
| `docs/` | Human study workflows, syllabus mapping and compatibility references |
| `artifacts/` | Ignored local keys, kubeconfigs, UI credentials, caches and verification reports |

## Run a certification lab

Run commands from the repository directory with `.venv` activated. For an
existing Kubernetes lab, select one profile, for example CAPA:

```bash
ansible-playbook -i setup/inventory setup/certification_lab.yml \
  -e @profiles/certifications/capa.yml
```

Use the same inventory and profile with `setup/validate_profile.yml` to check the
selection before creating or configuring hosts. The shared entry point selects
the two-cluster CCA workflow with `inventories/cca.ini`, or the CKA HA workflow
with `inventories/ha.ini`. LFCS and LFCA require their dedicated Linux inventories.

For a fresh local certification environment on macOS, use
`setup/fresh_certification.yml` with the same inventory and profile. On WSL,
the Windows launch command below provides the VM-management privileges:

```bash
pwsh.exe -NoProfile -File "$(wslpath -w scripts/hyperv_setup.ps1)" \
  -StartLab -WslDistribution "$WSL_DISTRO_NAME" -LinuxUser "$(id -un)" \
  -LabRepository "$PWD" -Certifications capa
```

A fresh certification run deletes **all managed lab VMs and their writable disks**,
then creates only the selected environment. To keep the other Linux guest, use
the targeted Linux workflow in the [Linux guide](docs/linux-certifications.md).
Normal configuration runs use `setup/certification_lab.yml` and require running,
SSH-accessible guests; they do not create or start VMs. After destroying the lab,
use the fresh workflow first. Replace `capa` with `ckad` in the Windows launch
command to create a fresh CKAD environment.

Fresh runs deliberately replace infrastructure. Existing-environment runs
reconcile managed configuration. Their default verification creates and removes
temporary workloads, so a successful repeat can report test-related changes.
For an installation-only repeat, add `-e run_certification_checks=false`; run the
matching test playbook afterwards. This option applies to Linux and Kubernetes profiles.

Connect with SSH for Linux exercises or use the selected Kubernetes context and
clients for Kubernetes exercises. Read `artifacts/access/current.yml` for selected
web interfaces. Recheck an existing environment with its matching inventory:

```bash
ansible-playbook -i setup/inventory tests/certification.yml \
  -e @profiles/certifications/capa.yml
ansible-playbook -i inventories/lfcs.ini tests/linux.yml \
  -e @profiles/certifications/lfcs.yml
ansible-playbook -i inventories/lfca.ini tests/linux.yml \
  -e @profiles/certifications/lfca.yml
```

## Choose an environment

### Home lab

Edit `setup/inventory`. Use the `cluster_nodes`, `control_plane`, and
`worker_nodes` groups. The account is `vboxuser`; the timezone is `Asia/Singapore`.
Vagrant provisions the account with the private SSH identity generated under
`artifacts/vagrant/`; the inventory uses that identity for Ansible.
The cloud inventory maps the same role groups to the Pluralsight servers.

Connect from the repository root in WSL or macOS with the shared lab key:

```bash
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.32  # master
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.34  # worker-01
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.35  # worker-02
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.40  # LFCS / AlmaLinux
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.41  # LFCA / Ubuntu LTS
```

Run these commands on the controller; the private key stays there. Fresh
certification runs replace the guests and their SSH host keys. Wait for the
Vagrant playbook's SSH identity checks to finish before connecting manually;
it refreshes the controller's trusted host keys through the managed connections.

The VM must be running before SSH can connect. Windows home VMs appear in
**Hyper-V Manager** with names beginning `kubeadm-`; macOS VirtualBox-provider
VMs appear in **VirtualBox Manager**. Vagrant uses the same guest account and key
for managed SSH access.

Ansible runs on WSL or macOS and configures the guests over SSH. In playbook
output, `localhost` means that controller; `guest -> localhost` marks work
delegated to it, such as preparing a CLI or fetching a kubeconfig.

```bash
ansible-playbook setup/hosts/vagrant.yml
ansible cluster_nodes -m ansible.builtin.ping
ansible-playbook setup/kube_cluster.yml
```

The Vagrant playbook creates the three main nodes in order and checks their OS,
CPU count, RAM, and inventory addresses. New guests are rebooted after provisioning
to check persistent configuration. Additional certification VMs remain stopped
until selected explicitly.
Starting an existing guest preserves its provisioned OS settings; an already
running guest needs no start operation. Pass `-e vagrant_reprovision=true` to
explicitly rerun the Vagrant guest provisioner. New guests always run it.

`scripts/vagrant.sh` installs Vagrant through Homebrew when necessary. On WSL,
it uses native Hyper-V and stages the Vagrantfile and provider state under
`%USERPROFILE%\Vagrant\kubeadm-ansible`. The shared Ansible private key stays in
WSL. Vagrant's extracted Linux runtime is shared inside its Homebrew package.
VM disks stay on Windows. Hyper-V uses DHCP for first boot, then persists the
inventory address, gateway and DNS for subsequent boots. Reserve those static
addresses outside the router's DHCP pool. macOS uses VirtualBox and defaults to the `en0`
bridge; override `VAGRANT_LAB_BRIDGE` for a different adapter.

Windows VM creation and deletion require Hyper-V management privileges. Use an
administrator terminal or the WSL launch command above. It reports any required
Windows restart. A comma-separated certification list runs fresh labs in sequence
and stops on failure; use one profile at a time for study.

```bash
ansible-playbook setup/hosts/vagrant.yml -e vagrant_state=status
ansible-playbook setup/hosts/vagrant.yml -e vagrant_state=stopped
ansible-playbook setup/hosts/vagrant.yml -e '{"vagrant_nodes":["ha-01","ha-02"]}'
```

Shared folders are disabled and the VMs use linked clones. Keep the pinned base
box while those clones exist. `vagrant_state=absent` destroys only the explicitly
selected machines in this Vagrant project.

### Pluralsight lab

```bash
cp inventories/pluralsight.ini.example inventories/pluralsight.ini
```

Replace the example hostnames with the current lab servers. This inventory uses
`cloud_user`, selects the `cloud_servers`, `master`, and `workers` groups, and
keeps a separate `pluralsight-kubeadm` context. The private inventory is gitignored.

```bash
ansible -i inventories/pluralsight.ini cloud_servers -m ansible.builtin.ping
ansible-playbook -i inventories/pluralsight.ini setup/kube_cluster.yml --ask-become-pass
```

Set `control_plane_endpoint=HOST:6443` when the Kubernetes API should use a
particular reachable hostname. Set each host's `node_ip` when its default network
interface is not the cluster interface. The endpoint must be chosen before init
so kubeadm includes it in the server certificate.

## Kubernetes versions

The default minor is 1.37 with Calico. Version pins are in
[setup/vars/common.yml](setup/vars/common.yml). See
[compatibility](docs/compatibility.md) before selecting add-ons.

For a **new** Kubernetes 1.36 lab that can also use the pinned Cilium,
cert-manager, and Rancher releases:

```bash
ansible-playbook -i inventories/pluralsight.ini setup/kube_cluster.yml \
  -e @profiles/kubernetes-1.36.yml --ask-become-pass
```

Bootstrap does not upgrade or downgrade an existing Kubernetes minor. Kubernetes
packages are held against unattended upgrades. Use the upstream kubeadm upgrade
procedure for an existing cluster.

## Access the selected cluster

Bootstrap fetches the current credentials, preserves other contexts, and selects
`vbox-kubeadm` or `pluralsight-kubeadm`. To refresh credentials after rebuilding:

```bash
ansible-playbook setup/cluster/fetch-kubeconfig.yml
kubectl get nodes
kubectl get pods -A
kubectl config get-contexts
```

Pass the cloud inventory to the fetch playbook when using Pluralsight. Set
`local_kube_context` to keep additional labs under distinct names. Set
`local_kubeconfig` for a destination other than `~/.kube/config`; if `KUBECONFIG`
is set in your shell, ensure it selects that file. Credentials in `artifacts/`
and the local kubeconfig are private and must not be committed.

## Optional playbooks

Pass the selected inventory to each command. Install only the tools needed for
the current exercise; follow the dependency order in [certification labs](docs/certifications.md).
The base cluster installs no certification add-ons. A fresh bootstrap with two
workers also runs temporary DNS and service-connectivity tests. Request these
on a later bootstrap run with `-e verify_network=true`.

| Playbook | Purpose |
| --- | --- |
| `setup/hosts/visudoers.yml` | Lab sudo access and timezone |
| `setup/hosts/bash-it.yml`, `setup/hosts/fzf.yml` | Guest shell tools |
| `setup/cluster/cni_install.yml` | Calico or Cilium; refuses to replace a different CNI |
| `setup/addons/argocd_install.yml` | Argo CD with TLS and dedicated NodePorts |
| `setup/addons/gitea.yml` | Gitea on the first worker, or `gitea_target_host` |
| `setup/addons/prometheus_stack_simple.yml` | Monitoring through an Argo CD Application |
| `setup/addons/istio_install.yml` | Istio and its ingress gateway |
| `setup/addons/bookinfo_deploy.yml` | Matching Bookinfo sample |
| `setup/addons/istio_addons.yml` | Matching demonstration dashboards |
| `setup/addons/certification_addons.yml` | Opt-in metrics-server and kube-bench |
| `setup/addons/loadbalancer.yml` | LoadBalancer practice with an explicitly reserved LAN pool and an external HTTP check |
| `setup/security/apparmor.yml` | AppArmor and seccomp profile directory |
| `setup/security/gvisor.yml` | gVisor and its RuntimeClass |
| `setup/security/falco_install.yml` | Falco runtime security |
| `setup/addons/rancher_install.yml` | Rancher on a compatible lab management cluster |
| `setup/maintenance/get-internal-ips.yml` | Selected guest addresses |
| `setup/hosts/repair_clone_identity.yml` | Unique machine IDs for cloned workers |

Examples:

```bash
ansible-playbook setup/addons/certification_addons.yml -e install_metrics_server=true
ansible-playbook setup/addons/certification_addons.yml -e install_kube_bench=true
ansible-playbook setup/cluster/verify_cluster.yml
```

Metrics-server's lab-only insecure kubelet TLS flag requires
`-e metrics_server_insecure_tls=true`. Certification setup refreshes the Kubernetes
context and authenticates the Argo CD CLI against the current installation.
Rancher requires an
explicit `rancher_host` and `bootstrap_password`; use Ansible Vault for secrets.
Gitea upgrades require a database backup and `allow_gitea_upgrade=true`.

NodePorts are allocated centrally in `setup/vars/common.yml`. Istio uses 30088
for HTTP and 30444 for HTTPS; Argo CD uses 30080 and 30443. The two monitoring
options have distinct dashboard ports.

After certification setup, read `artifacts/access/current.yml` for the active
URLs and client context. Login details are written only to
`artifacts/access/credentials.yml` (mode `0600`, ignored by Git). Fresh VM creation
replaces these credentials; bookmarks use the same node address.

| Interface | Home lab URL | Sign-in |
| --- | --- | --- |
| Argo CD | `https://192.168.101.32:30443` | `argocd` credentials entry |
| Argo Workflows | `https://192.168.101.32:30100/workflows/argo` | Paste the `workflows.authorization` value; select namespace `argo` |
| Grafana | `http://192.168.101.32:30086` | `grafana` credentials entry |
| Prometheus | `http://192.168.101.32:30084` | Local lab access |
| Alertmanager | `http://192.168.101.32:30081` | Local lab access |
| Backstage | `http://192.168.101.32:30097` | Choose **Guest** |
| Kiali, with Istio and monitoring | `http://192.168.101.32:30095/kiali` | Anonymous local lab access |
| Hubble, with Cilium | `http://192.168.101.32:30098` | Local lab access |
| Argo Rollouts | `http://localhost:3100` | Run `kubectl argo rollouts dashboard --port 3100 -n default` in WSL |

Only interfaces selected by the certification profile are installed. Open their
direct node URLs in the Windows browser; no WSL port-forward process is needed
for NodePort services. Istio itself has no management UI: Kiali displays its
mesh, while port `30088` serves configured application routes. Kiali uses the
existing Prometheus installation.

The Argo interfaces use a generated lab certificate with the node address in its
SANs. The CLI pins the public certificate at
`artifacts/access/argocd-server.crt`; a browser needs to trust this lab certificate.
It changes when the VMs are recreated. Workflow UI tokens are requested for
24 hours; refresh access without rebuilding the cluster with the same profile:

```bash
ansible-playbook setup/hosts/client_access.yml -e @profiles/certifications/cnpe.yml
```

Argo Workflows, Rollouts, Istio, Cilium, Kyverno and Crossplane clients use the
selected Kubernetes context. The workflow UI identity can manage workflows in
`argo`; choose `workflow-executor` as the workflow service account when submitting
from that interface.

## Disk usage

Guest Git clones use shallow history. `setup/hosts/fzf.yml` uses the Ubuntu package and
migrates clean upstream fzf clones. Versioned installer archives are removed
after extraction. Run cleanup after image imports or package installation:

```bash
ansible-playbook setup/maintenance/space_cleanup.yml
```

Cleanup preserves workloads and containerd data. Add
`-e prune_unused_images=true` only when unused images can be downloaded again.
To finish with disposable Linux labs, use
`setup/maintenance/linux_cleanup.yml` as described in the
[Linux guide](docs/linux-certifications.md#stop-destroy-and-reclaim-space).
`setup/maintenance/controller_cleanup.yml` clears completed Homebrew downloads
and pip caches while keeping installed controller tools and `.venv`.
`setup/maintenance/lab_cleanup.yml` destroys every managed local VM and its
writable disks, removes obsolete service-access details and clears lab caches.
Use the Windows launch option for VM deletion from WSL.

## Maintenance

```bash
ansible-playbook setup/maintenance/cluster-maintenance.yml -e action=status
ansible-playbook setup/maintenance/cluster-maintenance.yml -e action=shutdown
ansible-playbook setup/maintenance/cluster-maintenance.yml -e action=startup
```

Drain respects disruption budgets and stops on failure. Set
`drain_delete_emptydir_data=true` or `drain_force=true` only when required by the
exercise. `target_nodes` accepts inventory addresses or Kubernetes hostnames.

`setup/maintenance/kube_reset.yml` resets the selected cluster. It does not erase the whole
containerd store; optional unused-image pruning uses `reset_prune_images=true`.
Reserve inventory addresses by MAC before changing cloned machine identities.

## Validation

```bash
sh scripts/validate_playbooks.sh
```

The validator checks both inventory profiles, lints the playbooks, and tests
all certification/inventory contracts, lifecycle targeting, manifest overrides,
runtime configuration and kubeconfig isolation with temporary local files. It does
not deploy optional applications. Run `setup/cluster/verify_cluster.yml` for live base
cluster checks. To test DNS and cross-worker service traffic with temporary
BusyBox pods, run:

```bash
ansible-playbook tests/cluster_network.yml
ansible-playbook tests/cluster_runtime.yml
```

The network test requires two workers and removes its temporary namespace.
The runtime test uses a temporary guest configuration and leaves the running
service untouched.
