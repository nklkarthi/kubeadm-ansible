# Certification lab execution order

Select a certification profile and its inventory. Kubernetes profiles prepare
the functional cluster before their selected components; Linux profiles prepare
an isolated Linux guest. Run one certification environment at a time.

The [Golden Kubestronaut program](https://www.cncf.io/training/kubestronaut/)
currently includes 15 CNCF certifications plus LFCS, giving 16 in total.
Backstage is **CBA**, rather than BCA; **KCA** is Kyverno.
LFCA is an additional Linux Foundation certification supported by a separate profile.

## Base cluster

For a base-only Kubernetes lab, run from the repository root with the selected
inventory. Certification entry points include this step automatically:

```bash
ansible-playbook -i setup/inventory setup/kube_cluster.yml
kubectl get nodes
kubectl get pods -A
```

The base playbook installs containerd, kubeadm, kubelet, control-plane kubectl,
one CNI, and CoreDNS. It joins workers, fetches credentials, and checks node
readiness, inventory addresses, Kubernetes minor, network rollout, and DNS
rollout. A fresh bootstrap with two workers also tests DNS and cross-worker
service traffic using temporary pods. Shell frameworks, metrics, GitOps, dashboards, and security add-ons
are separate opt-in playbooks.

For cloud labs, replace `-i setup/inventory` with
`-i inventories/pluralsight.ini` in every command. The same commands work from
macOS and WSL. Check the current candidate handbook for the exam's tool and
Kubernetes versions; the newest lab release need not match an exam.
See [compatibility](compatibility.md) before choosing a profile.

## Select the certification

### Create a fresh local lab

The [README's WSL quick start](../README.md#create-a-fresh-lab-from-wsl)
covers controller activation, Windows consent and the expected SSH and Kubernetes
checks. Run the commands in the WSL terminal, from the repository directory.

On WSL, create a completely fresh CKAD lab in this order:

1. Open a WSL terminal in this repository and run `source .venv/bin/activate`.
2. Run the command below. It opens a Windows administrator consent prompt.
3. Select **Yes** in that prompt. The elevated Windows terminal runs Ansible
   back in WSL; leave it open until provisioning and verification finish.
4. Check that the run succeeds, then use `kubectl get nodes` from WSL. The
   launcher prepares the controller kubeconfig automatically.

```bash
source .venv/bin/activate
pwsh.exe -NoProfile -File "$(wslpath -w scripts/hyperv_setup.ps1)" -StartLab -WslDistribution "$WSL_DISTRO_NAME" -LinuxUser "$(id -un)" -LabRepository "$PWD" -Certifications ckad
```

The launcher selects the inventory and profile and runs
`setup/fresh_certification.yml`; there is no separate VM-creation command to run.
If Windows cancels the consent prompt, provisioning does not begin. Run the
command again and accept the prompt. Windows saves the run log at
`%LOCALAPPDATA%\Temp\kubeadm-hyperv\ckad-fresh.log`.

On macOS, or from WSL launched with Windows administrator privileges, activate
`.venv` in the repository directory and use Ansible directly:

```bash
ansible-playbook -i setup/inventory setup/fresh_certification.yml -e @profiles/certifications/ckad.yml
```

When splitting a Bash or Zsh command across lines, `\` must be the last character
on its line, immediately before the newline. Use the single-line form above to
avoid copying spaces after it.

This deletes the previous managed certification VMs and their writable disks,
creates clean guests from the cached OS image, verifies their new VM identities
and CPU stability, and then installs the selected environment. Only one
certification's VMs remain. Controller tools and immutable download caches are
shared; installed guest packages, workloads and practice data are recreated.

Use a comma-separated list such as `-Certifications ckad,kca,cba` to test several
environments sequentially. Each entry replaces the preceding environment; the
batch stops at its first failure. The helper selects the dedicated CCA, LFCS or
LFCA inventory automatically. CKA HA is opt-in.

### Configure an existing lab

To reconcile an existing environment without replacing its VMs, the guest setup
entry point remains available. Its guests must already be running and reachable
over SSH; it does not create or start VMs. After lab cleanup, run the fresh
workflow above first. For Pluralsight, allocate a new provider lab and
use this entry point with its inventory. The profile builds the base, installs
its selected components in dependency order, and runs its functional checks:

```bash
ansible-playbook -i setup/inventory setup/certification_lab.yml \
  -e @profiles/certifications/ckad.yml
```

For a fresh Kubernetes lab, add `-e rebuild_lab=true`. This resets the selected
inventory's cluster before rebuilding it; use a disposable practice cluster.
Choose one certification at a time. Each profile fixes compatible tool versions
rather than installing whichever release happens to be newest that day.

Both fresh and existing-environment entry points validate the selection before
changing hosts. Preview the same checks locally with:

```bash
ansible-playbook -i setup/inventory setup/validate_profile.yml \
  -e @profiles/certifications/ckad.yml
```

Use `inventories/cca.ini` for the two-cluster CCA lab, `inventories/ha.ini` for
the optional CKA HA lab, and the corresponding Linux inventory for LFCS/LFCA.
The existing-environment entry point routes these topologies automatically.
Use `-e run_certification_checks=false` for installation-only reconciliation;
the matching test playbook runs the functional checks separately.

| Certification | Prerequisites and component order | Practice focus |
| --- | --- | --- |
| KCNA — Kubernetes and Cloud Native Associate | None | Architecture, declarative workloads, service discovery, self-healing, batch workloads, cloud native concepts. |
| KCSA — Kubernetes and Cloud Native Security Associate | API audit logging | RBAC, Pod Security Admission, NetworkPolicy, secure workload configuration, audit events, threat models. |
| CKA — Certified Kubernetes Administrator | Metrics → dynamic storage → Traefik Ingress and Gateway API | Administration, etcd backup and restore, scheduling, storage, networking, troubleshooting. HA is a separate opt-in topology. |
| CKAD — Certified Kubernetes Application Developer | Worker Buildah → metrics → dynamic storage → Traefik Ingress and Gateway API | Image building, application configuration, probes, multi-container pods, Secrets, Jobs, volumes, routes, updates and rollback. |
| CKS — Certified Kubernetes Security Specialist | Controller supply-chain clients → worker Buildah → AppArmor → gVisor → Falco → kube-bench → Istio → audit logging → Traefik | Least privilege, host and runtime security, sandboxing, admission, isolation, audit, mTLS and supply-chain exercises. |
| PCA — Prometheus Certified Associate | Argo CD → kube-prometheus-stack | Instrumentation, ServiceMonitor, PromQL, recording rules, alerts, Alertmanager and Grafana. |
| ICA — Istio Certified Associate | Istio → Bookinfo | Traffic routing, gateways, subsets, mTLS, authorization and mesh troubleshooting. |
| CCA — Cilium Certified Associate | Cilium at bootstrap, using the Kubernetes 1.36 profile | Policy, connectivity, Hubble, ClusterMesh and BGP. Additional mesh networking must use distinct cluster identities and address ranges. |
| CAPA — Certified Argo Project Associate | Argo CD → Workflows → Rollouts → Events with JetStream | GitOps reconciliation, workflow DAGs, blue/green revisions, webhook-triggered Jobs. |
| CGOA — Certified GitOps Associate | Argo CD | Pinned Git sources, reconciliation, drift recovery, desired state and delivery principles. |
| CBA — Certified Backstage Associate | Backstage with a local SQLite lab database | Catalog ingestion, ownership, software templates, plugin and frontend development, TechDocs and integrations. |
| OTCA — OpenTelemetry Certified Associate | OpenTelemetry Collector | OTLP receivers, processors, logs, metrics, traces, API/SDK instrumentation and telemetry debugging. |
| KCA — Kyverno Certified Associate | Kyverno controllers and matching controller-side CLI | Mutation, validation, CEL policies, generation, image verification and policy testing. |
| CNPA — Cloud Native Platform Engineering Associate | Argo CD → Backstage | Developer portal, self-service, GitOps delivery, platform concepts and governance. |
| CNPE — Certified Cloud Native Platform Engineer | Controller supply-chain clients → worker Buildah → metrics → Argo CD → Istio → monitoring → audit logging → storage → Traefik → Workflows → Rollouts → Collector → Kyverno → Crossplane → Backstage | Platform APIs, delivery, self-service, operations, observability, security and policy. Uses the compatible Kubernetes 1.36 profile. |
| LFCS — Linux Foundation Certified System Administrator | Dedicated AlmaLinux guest; no Kubernetes | SELinux, users/ACLs, services, time, packages, networking, LVM/filesystems, containers, libvirt and recovery. |
| LFCA — Linux Foundation Certified IT Associate | Dedicated Ubuntu 24.04 LTS guest; no Kubernetes | Learning environment for the knowledge-based exam: Linux, APT/dpkg, services, networking, security, Git, containers, cloud and project-management concepts. |

Automated checks exercise specific behavior and record their scope in ignored
`artifacts/certification-results/` files. They do not replace the study and
troubleshooting exercises in the official curricula. Installing a component
alone does not demonstrate mastery of its exam domains.

### Optional CKA high availability lab

The normal home lab has one control plane and two workers. HA provisioned with
`inventories/ha.ini` uses three control planes and one worker, with an API proxy
on the worker. The two extra control planes use 2 CPUs and 2 GB each; Vagrant
stops worker-02 while they are needed. Do not start this topology for another
certification unless an exercise explicitly needs it.

From an administrator session on Windows, run the Hyper-V helper with
`-Inventory inventories/ha.ini -LabPlaybook setup/hosts/ha_lab.yml` in addition
to the WSL arguments shown in the README. Then build or rebuild the CKA profile
with `-i inventories/ha.ini`. Its checks include loss of the primary API server
and etcd process, an API write through the surviving quorum, and recovery.

To return to the usual topology, run the helper with
`-Inventory inventories/ha.ini -LabPlaybook setup/hosts/ha_cleanup.yml`.
This resets the HA cluster while its etcd members are reachable, removes the
API proxy, and destroys only the two extra control planes and their disks.
Run the helper with `-LabPlaybook setup/hosts/vagrant.yml` to restore the three
main VMs, then select the next certification profile with `rebuild_lab=true`.

### LFCS and LFCA Linux guests

Use `inventories/lfcs.ini` with `setup/hosts/linux_vms.yml` to create the optional
2 CPU, 2 GB guest. On Windows, pass that inventory and playbook to the same
administrator Hyper-V helper. This stops the three main Kubernetes VMs while
the Linux-only guest is selected. Once the guest is running:

```bash
ansible-playbook -i inventories/lfcs.ini setup/certification_lab.yml \
  -e @profiles/certifications/lfcs.yml
```

LFCS keeps SELinux enforcing; LFCA uses Ubuntu's AppArmor and UFW. Practice services and storage use the dedicated Linux
guest so that Linux administration exercises cannot change the Kubernetes hosts.
The storage checks create a small sparse loop device, verify LVM growth and
filesystem persistence, and remove that device afterwards.

Run one of these commands from the repository directory in WSL or macOS:

```bash
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.40  # LFCS
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.41  # LFCA
```

After connecting, run `sudo -i` inside the guest for administration exercises.
Each VM must be running. Use `inventories/lfca.ini` and the LFCA profile for the
LFCA guest. `setup/hosts/linux_vms.yml` starts the selected Linux guest and stops
the main Kubernetes VMs; it preserves other Linux guests.
`setup/fresh_certification.yml` instead deletes all managed VMs before creating
the selected certification environment.

The [Linux study guide](linux-certifications.md) maps all LFCS objectives to
prepared tools and exercises. LFCS uses AlmaLinux for the RHEL-family skills;
LFCA uses Ubuntu LTS for Debian-family practice. LFCA is a multiple-choice exam,
so its automated checks validate the learning environment rather than exam tasks.
The [practical lab guide](practical-labs.md) covers task-driven LFCS, CKA, CKS, CNPE
and CKAD workflows, with verification and cleanup.

| Area | AlmaLinux / Rocky Linux | Ubuntu Server |
| --- | --- | --- |
| Packages | `dnf`, `rpm` | `apt`, `dpkg` |
| Apache service | `httpd` | `apache2` |
| Network configuration | NetworkManager / `nmcli` | Netplan with the configured network backend |
| Default mandatory access control | SELinux | AppArmor; this does not replace SELinux practice |

## Recipes

Pass the selected inventory to each command, and run the listed files in order.

### Kubernetes administration and development

The base cluster is sufficient to begin CKA and CKAD exercises. Add metrics only
when practising resource metrics, `kubectl top`, or autoscaling:

```bash
ansible-playbook setup/addons/certification_addons.yml -e install_metrics_server=true
```

Kubelet serving certificates must be trusted by metrics-server. For a lab that
explicitly needs insecure serving-certificate verification, also pass
`-e metrics_server_insecure_tls=true`.

### Cilium

Choose Cilium when creating a **new** lab. The pinned release currently requires
the Kubernetes 1.36 profile. Have Helm installed on the controller:

```bash
ansible-playbook setup/kube_cluster.yml \
  -e @profiles/kubernetes-1.36.yml -e cni_plugin=cilium
```

Do not run this against an existing Calico cluster. Changing CNI requires a
separate migration or a deliberately rebuilt lab. Do not downgrade an existing
Kubernetes 1.37 cluster by selecting the 1.36 profile.

### GitOps and Prometheus

```bash
ansible-playbook setup/addons/argocd_install.yml
# Run only for monitoring exercises:
ansible-playbook setup/addons/prometheus_stack_simple.yml
```

Gitea is optional: use an existing Git service if it suits the exercise. Rancher
is also optional; it is not a dependency of these certification paths.

### Istio

```bash
ansible-playbook setup/addons/istio_install.yml
ansible-playbook setup/addons/bookinfo_deploy.yml
# Run only when demonstration dashboards are needed:
ansible-playbook setup/addons/istio_addons.yml
```

The sample dashboards are for mesh demonstrations. Configure a tracing provider
and workload instrumentation when the exercise needs tracing. Avoid installing
a second monitoring stack unless the exercise calls for it.

### Security

Run the tool for the current exercise rather than installing them all:

```bash
ansible-playbook setup/security/apparmor.yml
# Sandboxed-runtime exercise:
ansible-playbook setup/security/gvisor.yml
# Runtime detection exercise:
ansible-playbook setup/security/falco_install.yml
# CIS assessment exercise:
ansible-playbook setup/addons/certification_addons.yml -e install_kube_bench=true
```

Installing a tool prepares the lab; it does not complete its certification
exercises or prove coverage of the full curriculum.

### Backstage development

The CBA profile provides a running portal, catalog and software template.
The [CBA curriculum](https://training.linuxfoundation.org/certification/certified-backstage-associate-cba/)
also requires local development, TypeScript, React, Material UI and plugin
customization. Use a separate application directory outside this repository
for those exercises. The Backstage 1.55.2 release uses app generator 0.9.2 and
supports Node.js 22 or 24:

```bash
ansible-playbook -i setup/inventory setup/hosts/controller_tools.yml \
  -e @profiles/certifications/cba.yml
mkdir -p "$HOME/backstage-practice"
cd "$HOME/backstage-practice"
# Choose practice-backstage when prompted for the application name:
npx --yes @backstage/create-app@0.9.2
cd practice-backstage
corepack yarn install
corepack yarn tsc
corepack yarn build:backend
corepack yarn start
```

Follow the [Backstage development guide](https://backstage.io/docs/getting-started/)
to change a React component, add frontend and backend plugins, register a catalog
location and build the application's container image. Keep generated bundles,
`node_modules`, local credentials and container images outside Git. The portal's
SQLite database and guest authentication are intended for disposable exercises;
use persistent storage and an appropriate identity provider for production.

### Telemetry and policy authoring

After the OTCA profile's HTTP and SDK-generated gRPC checks, instrument a small
application using the [OpenTelemetry language SDKs](https://opentelemetry.io/docs/languages/).
Carry trace context and baggage across two calls, compare sampling decisions,
correlate logs with spans, and change Collector transformations and error handling.
These exercises cover API and SDK behavior beyond accepting OTLP payloads.

For KCA, the checks exercise admission mutation, CEL denial and the controller's
`kyverno apply`, `test` and `jp` commands. Continue with generation, image
verification, background reports, policy exceptions, cleanup and metrics using
the [Kyverno guides](https://kyverno.io/docs/). Compare traditional policy types
with CEL policies before attempting an upgrade or high availability exercise.

## Controller clients

Run the clients from WSL or macOS, using the selected lab's kubeconfig. Profile
setup installs only the clients required by its selected components. Installed
clients can be shared between fresh labs; they run when invoked.
See [service access](../README.md#optional-playbooks) for initialized logins,
active UI endpoints and access refresh commands.

| Selected component | Controller clients |
| --- | --- |
| Kubernetes base | `kubectl`, Helm and crane |
| CKA, CKAD, CKS and CNPE practice | Kustomize |
| Argo CD | `argocd` and Kustomize |
| Argo Workflows | `argo` |
| Argo Rollouts | `kubectl argo rollouts`, from the official `argoproj/tap` |
| Istio | `istioctl` |
| Cilium | `cilium` and `hubble` |
| Kyverno | `kyverno` |
| Crossplane | `crossplane` |
| Backstage development | Node 24, npm, Corepack and Yarn 4 |
| CKS and CNPE supply-chain practice | Syft, Cosign, Trivy and KubeLinter |
| OpenTelemetry | `kubectl` for the Collector and SDK packages in the application being instrumented |
| Linux-only labs | SSH and Ansible on the controller; Linux administration tools inside the selected guest |

Kubernetes 1.37's client supports the 1.36 and 1.37 cluster profiles under the
[kubectl version-skew policy](https://kubernetes.io/releases/version-skew-policy/#kubectl).
Other client releases are pinned separately where their upstream release lines
differ from their controllers. The Argo CD CLI uses an Argo CD server login, or
core mode with a kubeconfig context whose namespace is `argocd`; a normal
Kubernetes context alone does not provide an Argo CD server login.

For a WSL application sending OTLP telemetry, forward the selected Collector:

```bash
kubectl -n opentelemetry port-forward service/otel-collector 4317:4317 4318:4318
```

Point the application's OTLP exporter at the appropriate localhost endpoint.
The Collector, mesh, policy and delivery controllers remain in the cluster.

## Resources and cleanup

Keep the base cluster and one exercise stack active at a time. Measure VM RAM
and storage before adding observability or platform components. Use separate
labs when exercises require incompatible Kubernetes versions or CNIs.

To replace the current local certification environment with a clean minimal
Kubernetes cluster, run `setup/fresh_cluster.yml` with the home inventory. On
Windows, pass `-LabPlaybook setup/fresh_cluster.yml` to the administrator
Hyper-V helper. This removes the selected certification's VMs and writable
disks, recreates the three main guests, and verifies the functional base.

```bash
ansible-playbook setup/cluster/verify_cluster.yml
ansible-playbook setup/maintenance/space_cleanup.yml
```

Cleanup removes known image-import staging files and APT archives. It preserves
installed workloads and containerd data. Unused image pruning is opt-in with
`-e prune_unused_images=true` and may require later downloads.

Consult the [official certification catalog](https://www.cncf.io/training/certification/)
and [published curricula](https://github.com/cncf/curriculum) for current domains.
The [CKS requirements](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)
and [CNPE instructions](https://docs.linuxfoundation.org/tc-docs/certification/important-instructions-cnpe)
provide the respective exam prerequisites and environment details.

## Recent GitHub study guides

These repositories were created between **9 November 2025 and 9 November 2026**,
according to GitHub repository metadata. README revisions identify the material
reviewed; creation dates can be checked with `gh api repos/OWNER/REPO --jq .created_at`.

| Guide | Coverage | Repository created | README revision |
| --- | --- | --- | --- |
| [Golden Kubestronaut study guide](https://github.com/slauger/kubestronaut) | Study guides covering all 16 certifications | 31 March 2026 | [7 April 2026](https://github.com/slauger/kubestronaut/commit/846b1cb39159f7fbb45f6197f7e5287a31258b40) |
| [Golden Kubestronaut learning path](https://github.com/pmady/golden-kubestronaut-learning) | Certification chapters and study sequence | 18 December 2025 | [4 January 2026](https://github.com/pmady/golden-kubestronaut-learning/commit/c0cdcca28b82bd6b7da2824479f4eb7a3d0583af) |
| [CNPE practice platform](https://github.com/rbstp/cnpe-exam-prep) | Platform APIs, delivery, operations, observability and security exercises | 22 August 2026 | [17 September 2026](https://github.com/rbstp/cnpe-exam-prep/commit/a1fcb7e6cb1f78f08bf30cbecddbe24ab851d3a4) |
| [CAPA study guide](https://github.com/msahihi/CAPA-study-guide) | Argo CD, Workflows, Rollouts and Events domains and labs | 26 January 2026 | [13 February 2026](https://github.com/msahihi/CAPA-study-guide/commit/f509a371f6fae23e769915c9e123e3b4b1fd18b3) |
| [KCNA study guide](https://github.com/msahihi/KCNA-study-guide) | Kubernetes and cloud native fundamentals | 25 January 2026 | [25 January 2026](https://github.com/msahihi/KCNA-study-guide/commit/8239cd9973c6c479f9833f4798cb7802e6f3aded) |
| [KCSA study guide](https://github.com/msahihi/KCSA-study-guide) | Security concepts and Kubernetes security domains | 13 March 2026 | [13 March 2026](https://github.com/msahihi/KCSA-study-guide/commit/a0ef100adddd583b5dd9f7d3fe3ba828da6f7488) |
| [LFCS multi-distribution practice lab](https://github.com/Zeukkari/lfcs-test-lab) | Domain notes and Ubuntu/Rocky/SUSE exercises, including multi-node practice | 3 November 2026 | [3 November 2026](https://github.com/Zeukkari/lfcs-test-lab/commit/20ad32e997043b1d81484e85e288c6720bd34e15) |

Use these for practice alongside the official curricula. A recent creation date
does not establish curriculum accuracy or compatibility with this lab's versions.
Select the playbooks from the certification table above and the tool versions
from the compatibility table; do not run a guide's entire installation script
on an existing cluster.
