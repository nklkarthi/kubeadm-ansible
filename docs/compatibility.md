# Compatibility

Versions are pinned in [common.yml](../setup/vars/common.yml). A newer release of
one component does not imply that it supports the newest Kubernetes minor.
Update the pin, release checksum and Kubernetes range together when changing a release line.

| Component | Pinned release | Kubernetes support used by these playbooks |
| --- | --- | --- |
| Kubernetes | 1.37 minor | Default fresh-cluster profile |
| Calico | 3.33.0 | 1.35–1.37 |
| Cilium | 1.20.4 | 1.33–1.36; installer stops on 1.37 |
| Argo CD | 3.6.1 | 1.34–1.37 |
| Istio | 1.31.4 | 1.32–1.37; CLI and samples use this same release |
| metrics-server | 0.9.1 | Check kubelet authentication and serving certificates |
| kube-bench | 0.16.0 | Installation only; select an appropriate CIS benchmark when running it |
| kube-prometheus-stack | 93.1.0 | Chart declares Kubernetes >=1.25; this repo targets supported cluster minors |
| cert-manager | 1.21.3 | 1.33–1.36 |
| Rancher | 2.15.3 | Management range 1.34–1.36; kubeadm labs are not vendor-certified management distributions |
| gVisor | 20261102.0 | Full runtime bundle, sidecars and containerd 2.x |
| Falco | 0.45.2 | `modern_ebpf` requires kernel BTF; `kmod` requires matching headers |
| Gitea | 28.3.0 | Guest service, independent of Kubernetes APIs |
| Bash-it | 3.2.0 | Guest shell framework |
| ingress-nginx | 1.15.1 | Retired; explicit historical-lab option and Kubernetes 1.31–1.35 only |

The fresh Kubernetes 1.36 profile is the common choice for the pinned Cilium,
cert-manager and Rancher releases. Do not apply that profile as a downgrade to an
existing 1.37 cluster. Calico remains the default CNI for 1.37. Changing an existing
cluster between Calico and Cilium requires a separate migration or rebuild.

The controller toolchain uses Ansible Core 2.21.6 with Python 3.12–3.14 on macOS or
WSL. Homebrew manages controller tools; the preparation playbook verifies their
versions against the pins before using them. Guests use their own distribution's
Python interpreter and APT or DNF packages. Kubernetes operations run on the
selected Ubuntu control plane with its explicit admin kubeconfig. LFCS and LFCA
use dedicated AlmaLinux 10.2 guests without Kubernetes.

Controller clients are selected by component in `setup/hosts/controller_tools.yml`.
The Argo Rollouts Homebrew tap currently provides client 1.10.0 for the 1.10.2
controller. The standalone Crossplane CLI is pinned to 2.5.0 independently of
Crossplane core 2.4.3. Backstage development uses Node 24.22.2, Corepack 0.36.0
and Yarn 4.18.0. Homebrew manages Node; npm installs Corepack without pulling a
second, unsupported Node major through the Corepack Homebrew formula.

Istio demonstration add-ons are intended for exercises. Installing Jaeger does
not configure an application tracing provider automatically. Configure Istio's
tracing provider before creating tracing policies.

## Upstream references

- [Kubernetes installation requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Calico system requirements](https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements)
- [Cilium Kubernetes compatibility](https://docs.cilium.io/en/stable/network/kubernetes/compatibility/)
- [Argo CD tested Kubernetes versions](https://argo-cd.readthedocs.io/en/stable/operator-manual/tested-kubernetes-versions/)
- [Istio supported releases](https://istio.io/latest/docs/releases/supported-releases/)
- [cert-manager supported releases](https://cert-manager.io/docs/releases/)
- [Rancher 2.15.3 support matrix](https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/rancher-v2-15-3/)
- [Prometheus Helm charts](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [gVisor installation](https://gvisor.dev/docs/user_guide/install/)
- [Falco installation](https://falco.org/docs/setup/)
- [Ingress NGINX retirement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
