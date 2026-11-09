# Certification lab execution order

Start with a functional base cluster. Add tools only for the certification and
exercise you are working on. Do not install every stack on the home VMs.

The [Golden Kubestronaut program](https://www.cncf.io/training/kubestronaut/)
currently includes 15 CNCF certifications plus LFCS, giving 16 in total.
Backstage is **CBA**, rather than BCA; **KCA** is Kyverno.

## Base cluster

Run from the repository root with the selected inventory:

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

Select one profile from the repository root. The profile builds the base, installs
its selected components in dependency order, and runs its functional checks:

```bash
ansible-playbook -i setup/inventory setup/certification_lab.yml \
  -e @profiles/certifications/ckad.yml
```

For a fresh Kubernetes lab, add `-e rebuild_lab=true`. This resets the selected
inventory's cluster before rebuilding it; use a disposable practice cluster.
Choose one certification at a time. Each profile fixes compatible tool versions
rather than installing whichever release happens to be newest that day.

| Certification | Components after the functional base | Practice focus |
| --- | --- | --- |
| KCNA — Kubernetes and Cloud Native Associate | None | Architecture, declarative workloads, service discovery, self-healing, batch workloads, cloud native concepts. |
| KCSA — Kubernetes and Cloud Native Security Associate | API audit logging | RBAC, Pod Security Admission, NetworkPolicy, secure workload configuration, audit events, threat models. |
| CKA — Certified Kubernetes Administrator | Metrics → dynamic storage → Traefik Ingress and Gateway API | Administration, etcd backup and restore, scheduling, storage, networking, troubleshooting. HA is a separate opt-in topology. |
| CKAD — Certified Kubernetes Application Developer | Dynamic storage → Traefik Ingress and Gateway API | Application configuration, probes, multi-container pods, Secrets, Jobs, volumes, routes, updates and rollback. |
| CKS — Certified Kubernetes Security Specialist | AppArmor → gVisor → Falco → kube-bench → Istio → audit logging → Traefik | Least privilege, host and runtime security, sandboxing, admission, isolation, audit, mTLS and supply-chain exercises. |
| PCA — Prometheus Certified Associate | Argo CD → kube-prometheus-stack | Instrumentation, ServiceMonitor, PromQL, recording rules, alerts, Alertmanager and Grafana. |
| ICA — Istio Certified Associate | Istio → Bookinfo | Traffic routing, gateways, subsets, mTLS, authorization and mesh troubleshooting. |
| CCA — Cilium Certified Associate | Cilium at bootstrap, using the Kubernetes 1.36 profile | Policy, connectivity, Hubble, ClusterMesh and BGP. Additional mesh networking must use distinct cluster identities and address ranges. |
| CAPA — Certified Argo Project Associate | Argo CD → Workflows → Rollouts → Events with JetStream | GitOps reconciliation, workflow DAGs, blue/green revisions, webhook-triggered Jobs. |
| CGOA — Certified GitOps Associate | Argo CD | Pinned Git sources, reconciliation, drift recovery, desired state and delivery principles. |
| CBA — Certified Backstage Associate | Backstage with a local SQLite lab database | Catalog ingestion, ownership, software templates, plugin and frontend development, TechDocs and integrations. |
| OTCA — OpenTelemetry Certified Associate | OpenTelemetry Collector | OTLP receivers, processors, logs, metrics, traces, API/SDK instrumentation and telemetry debugging. |
| KCA — Kyverno Certified Associate | Kyverno controllers and matching controller-side CLI | Mutation, validation, CEL policies, generation, image verification and policy testing. |
| CNPA — Cloud Native Platform Engineering Associate | Argo CD → Backstage | Developer portal, self-service, GitOps delivery, platform concepts and governance. |
| CNPE — Certified Cloud Native Platform Engineer | Argo CD → monitoring → Istio → storage → Traefik → Workflows → Rollouts → Collector → Kyverno → Crossplane → Backstage | Platform APIs, delivery, self-service, operations, observability, security and policy. Uses the compatible Kubernetes 1.36 profile. |
| LFCS — Linux Foundation Certified System Administrator | Dedicated AlmaLinux guest; no Kubernetes | SELinux, users/ACLs, services, time, packages, networking, LVM/filesystems, containers, libvirt and recovery. |

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

### LFCS Linux guest

Use `inventories/lfcs.ini` with `setup/hosts/linux_vms.yml` to create the optional
2 CPU, 2 GB guest. On Windows, pass that inventory and playbook to the same
administrator Hyper-V helper. Once the guest is running:

```bash
ansible-playbook -i inventories/lfcs.ini setup/certification_lab.yml \
  -e @profiles/certifications/lfcs.yml
ssh -i artifacts/vagrant/id_ed25519 vboxuser@192.168.101.40
```

SELinux stays enforcing. Practice services and storage use the dedicated Linux
guest so that Linux administration exercises cannot change the Kubernetes hosts.
The storage checks create a small sparse loop device, verify LVM growth and
filesystem persistence, and remove that device afterwards.

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

## Resources and cleanup

Keep the base cluster and one exercise stack active at a time. Measure VM RAM
and storage before adding observability or platform components. Use separate
labs when exercises require incompatible Kubernetes versions or CNIs.

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

These repositories have README commits between **9 November 2025 and
9 November 2026**. Dates link to the corresponding commits, so recency can be
checked independently of search-engine crawl dates.

| Guide | Coverage | README update |
| --- | --- | --- |
| [Awesome Kubestronaut](https://github.com/yetmike/awesome-kubestronaut) | Resources grouped by all 16 certifications, with links to project documentation and labs | [13 October 2026](https://github.com/yetmike/awesome-kubestronaut/commit/2c28c738530e0d23057fd272f1c9c51deeb9d5b9) |
| [Golden Kubestronaut study guide](https://github.com/slauger/kubestronaut) | Study guides covering all 16 certifications | [7 April 2026](https://github.com/slauger/kubestronaut/commit/846b1cb39159f7fbb45f6197f7e5287a31258b40) |
| [Golden Kubestronaut learning path](https://github.com/pmady/golden-kubestronaut-learning) | Certification chapters and study sequence | [4 January 2026](https://github.com/pmady/golden-kubestronaut-learning/commit/c0cdcca28b82bd6b7da2824479f4eb7a3d0583af) |
| [CKA preparation guide](https://github.com/techiescamp/cka-certification-guide) | Administration, networking, storage, workloads, and troubleshooting exercises | [5 November 2026](https://github.com/techiescamp/cka-certification-guide/commit/3d2cbc90389e5dbd82ae0755bc9068ca16ae5cb5) |
| [CGOA study guide](https://github.com/otkd/CGOA-Study-Guide) | GitOps principles and reference material | [18 September 2026](https://github.com/otkd/CGOA-Study-Guide/commit/34a62fdea7c5bc8827c47e9783265ff42384098b) |
| [CAPA study guide](https://github.com/msahihi/CAPA-study-guide) | Argo CD, Workflows, Rollouts and Events domains and labs | [13 February 2026](https://github.com/msahihi/CAPA-study-guide/commit/f509a371f6fae23e769915c9e123e3b4b1fd18b3) |
| [KCNA study guide](https://github.com/msahihi/KCNA-study-guide) | Kubernetes and cloud native fundamentals | [25 January 2026](https://github.com/msahihi/KCNA-study-guide/commit/8239cd9973c6c479f9833f4798cb7802e6f3aded) |
| [KCSA study guide](https://github.com/msahihi/KCSA-study-guide) | Security concepts and Kubernetes security domains | [13 March 2026](https://github.com/msahihi/KCSA-study-guide/commit/a0ef100adddd583b5dd9f7d3fe3ba828da6f7488) |
| [CKS crash course](https://github.com/bmuschko/cks-crash-course) | Security exercises and solutions | [17 November 2025](https://github.com/bmuschko/cks-crash-course/commit/8114283c5b5b83e8e73ac9867ab4c71cdd147e9f) |

Use these for practice alongside the official curricula. A recent README update
does not establish compatibility with the Kubernetes version in this lab.
Select the playbooks from the certification table above and the tool versions
from the compatibility table; do not run a guide's entire installation script
on an existing cluster.
