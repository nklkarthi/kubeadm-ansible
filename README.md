# kubeadm-ansible

Create Ubuntu Kubernetes labs from a macOS or WSL Ansible controller. Use the
home inventory or a separate Pluralsight inventory while travelling.

## Requirements

- Controller: macOS or WSL, Python 3.12–3.14, Ansible, and `kubectl`.
- Guests: Ubuntu 22.04 or newer, unique hostnames/MACs, SSH access, and sudo.
- Home VMs: Ubuntu 24.04 LTS, 2 CPUs and 4 GB RAM per node.
- Guest addresses must be stable and reachable from each other and the controller.
- Pod and service networks must not overlap the guest networks.
- The controller-tools playbook prepares pinned Helm and registry clients when needed.
- Home VM management uses Vagrant and Homebrew, with native Hyper-V on Windows
  or VirtualBox on macOS.

Install the controller tools in a virtual environment:

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
```

Ubuntu controllers need the matching `python3.14-venv` package for the standard
`venv` command. Activate `.venv` before running validation or deployment.

## Repository layout

- `setup/kube_cluster.yml`: base-cluster entry point.
- `Vagrantfile`, `setup/hosts/vagrant.yml`: local VM definitions and lifecycle.
- `setup/cluster/`: bootstrap, CNI, credentials, and cluster verification.
- `setup/addons/`: opt-in applications and certification tools.
- `setup/security/`: opt-in host and runtime security tools.
- `setup/hosts/`: firewall, accounts, shell tools, and clone identity.
- `setup/maintenance/`: status, drain/recovery, reset, and disk cleanup.
- `setup/tasks/`, `setup/templates/`, `setup/vars/`: shared implementation and version pins.
- `inventories/`, `profiles/`: environment inventory examples and version overrides.
- `tests/`: local task tests and an explicit live network test.

## Choose an environment

### Home lab

Edit `setup/inventory`. The default groups are `vbox_hosts`, `vbox_master`, and
`vbox_workers`. The account is `vboxuser`; the timezone is `Asia/Singapore`.
Vagrant provisions the account with the private SSH identity generated under
`artifacts/vagrant/`; the inventory uses that identity for Ansible.
The canonical `cluster_nodes`, `control_plane`, and `worker_nodes` groups map
to these home groups; the cloud inventory maps them to its own hosts.

Connect from the repository root in WSL or macOS with the shared lab key:

```bash
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.32  # master
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.34  # worker-01
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.35  # worker-02
```

The VM must be running before SSH can connect. Windows home VMs appear in
**Hyper-V Manager** with names beginning `kubeadm-`; macOS VirtualBox-provider
VMs appear in **VirtualBox Manager**. Vagrant uses the same guest account and key
for managed SSH access.

```bash
ansible-playbook setup/hosts/vagrant.yml
ansible vbox_hosts -m ansible.builtin.ping
ansible-playbook setup/kube_cluster.yml
```

The Vagrant playbook creates the three main nodes in order and checks their OS,
CPU count, RAM, and inventory addresses. New guests are rebooted after provisioning
to check persistent configuration. Additional certification VMs remain stopped
until selected explicitly.

`scripts/vagrant.sh` installs Vagrant through Homebrew when necessary. On WSL,
it uses native Hyper-V and stages the Vagrantfile and provider state under
`%USERPROFILE%\Vagrant\kubeadm-ansible`. The shared Ansible private key stays in
WSL. VM disks stay on Windows. Hyper-V uses DHCP for first boot, then persists the
inventory address, gateway and DNS for subsequent boots. Reserve those static
addresses outside the router's DHCP pool. macOS uses VirtualBox and defaults to the `en0`
bridge; override `VAGRANT_LAB_BRIDGE` for a different adapter.

On Windows, run `scripts/hyperv_setup.ps1` in an administrator PowerShell session
once to enable Hyper-V, grant the current user Hyper-V management access, and
create the external `kubeadm-lab` switch. Windows may require a restart. Use a new
Windows sign-in after group membership changes, or run the Vagrant lifecycle
from an administrator session.

To prepare Hyper-V and run VM provisioning, CPU checks, and the base cluster in
one administrator session, use PowerShell with this checkout's WSL path:

```powershell
& '\\wsl.localhost\Ubuntu\home\nklkarthi\github.com\nklkarthi\kubeadm-ansible\scripts\hyperv_setup.ps1' `
  -StartLab -WslDistribution Ubuntu -LinuxUser nklkarthi `
  -LabRepository /home/nklkarthi/github.com/nklkarthi/kubeadm-ansible
```

Adjust the distribution, Linux user and checkout path on another controller.
If the script reports `restart-required`, restart Windows and repeat it.

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
| `setup/security/apparmor.yml` | AppArmor and seccomp profile directory |
| `setup/security/gvisor.yml` | gVisor and its RuntimeClass |
| `setup/security/falco_install.yml` | Falco runtime security |
| `setup/addons/rancher_install.yml` | Rancher on a compatible lab management cluster |
| `setup/addons/ingress_nginx.yml` | Historical ingress-nginx exercises only |
| `setup/maintenance/get-internal-ips.yml` | Selected guest addresses |
| `setup/hosts/repair_clone_identity.yml` | Unique machine IDs for cloned workers |

Examples:

```bash
ansible-playbook setup/addons/certification_addons.yml -e install_metrics_server=true
ansible-playbook setup/addons/certification_addons.yml -e install_kube_bench=true
ansible-playbook setup/cluster/verify_cluster.yml
```

Metrics-server's lab-only insecure kubelet TLS flag requires
`-e metrics_server_insecure_tls=true`. Argo CD uses HTTPS by default; retrieving
its initial admin secret is a separate `kubectl` operation. Rancher requires an
explicit `rancher_host` and `bootstrap_password`; use Ansible Vault for secrets.
Gitea upgrades require a database backup and `allow_gitea_upgrade=true`.

NodePorts are allocated centrally in `setup/vars/common.yml`. Istio uses 30088
for HTTP and 30444 for HTTPS; Argo CD uses 30080 and 30443. The two monitoring
options have distinct dashboard ports.

## Disk usage

Guest Git clones use shallow history. `setup/hosts/fzf.yml` uses the Ubuntu package and
migrates clean upstream fzf clones. Versioned installer archives are removed
after extraction. Run cleanup after image imports or package installation:

```bash
ansible-playbook setup/maintenance/space_cleanup.yml
```

Cleanup preserves workloads and containerd data. Add
`-e prune_unused_images=true` only when unused images can be downloaded again.

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
manifest overrides, runtime configuration, and kubeconfig isolation with
temporary local files. It does
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
