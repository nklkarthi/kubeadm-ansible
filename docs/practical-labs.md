# Practical certification workflows

Use these as original learning exercises alongside the official curricula and
the [recent GitHub references](certifications.md#recent-github-study-guides).
Start with a working baseline, make one
controlled failure, diagnose it from evidence, restore service, and clean up.

## Prepare, practise and verify

| Certification | Profile | Detailed exercise material | Automated verification |
| --- | --- | --- | --- |
| LFCS | `profiles/certifications/lfcs.yml` | [Every objective and Linux practice sequence](linux-certifications.md) | `tests/linux.yml`, `tests/tasks/lfcs_practical.yml`, `tests/tasks/lfcs_tools.yml` |
| CKA | `profiles/certifications/cka.yml` | Cluster lifecycle, scheduling, networking, storage and troubleshooting below | `tests/tasks/cka.yml`, `tests/tasks/storage_routes.yml`; HA checks only for a selected multi-control-plane topology |
| CKS | `profiles/certifications/cks.yml` | Runtime confinement, access boundaries, delivery integrity and investigation below | `tests/tasks/cks.yml`, `tests/tasks/kcsa.yml` |
| CNPE | `profiles/certifications/cnpe.yml` | Tenancy, delivery, platform APIs and incident recovery below | `tests/tasks/cnpe.yml` and its component checks |
| CKAD | `profiles/certifications/ckad.yml` | Application build, rollout, configuration, connectivity and debugging below | `tests/tasks/ckad.yml`, `tests/tasks/storage_routes.yml` |

Create only the selected environment using the [README workflow](../README.md#run-a-certification-lab).
For existing Kubernetes VMs, configure and verify one selected profile:

```bash
ansible-playbook -i setup/inventory setup/certification_lab.yml \
  -e @profiles/certifications/ckad.yml
```

Replace `ckad` with `cka`, `cks` or `cnpe` as needed. A fresh certification run replaces
all managed VMs; it is a deliberate reset, not a prerequisite for every exercise.
Kubernetes profiles use the current kubeconfig and prepare their applicable CLIs.
CKS and CNPE automatically install the supply-chain clients. To prepare those
clients separately without creating VMs:

```bash
ansible-playbook setup/hosts/supply_chain_tools.yml
```

This verifies the pinned Homebrew versions of Syft, Cosign, Trivy and KubeLinter on
WSL/macOS, installing missing packages. The guests do not need these controller binaries. Vulnerability scans
may download a database; use `artifacts/practice/trivy-cache` for disposable data.

Choose a separate namespace for your work, such as `practice-cka`, `practice-ckad`, `practice-cks`
or `practice-cnpe`. Keep manifests and generated output under the ignored
`artifacts/practice/` directory. Every task should have an observable acceptance
condition; creating a YAML object alone is insufficient.

The Ansible checks create their own temporary namespaces and remove them.
Run them to verify the baseline and read their task files as implementation
references. Your exercise namespaces remain separate so you can inspect and
repair them yourself.
Shared boundary checks use a separate temporary namespace to prove allowed and
denied RBAC requests, cross-namespace isolation, restricted admission, real
NetworkPolicy traffic and quota rejection without changing your exercises.

### Provisioned prerequisites

Every exercise below uses these declared setup paths. Selecting a profile
installs its prerequisites; the exercises are work for the learner.

| Practice prerequisite | Ansible setup | Selected by |
| --- | --- | --- |
| kubectl, Helm and Kustomize | `setup/hosts/controller_tools.yml` | CKA, CKAD, CKS, CNPE |
| Node network/process/TLS/Git diagnosis tools | `setup/hosts/practical_tools.yml` | CKA, CKAD, CKS, CNPE |
| Buildah on the first worker, using its own image storage | `setup/hosts/practical_tools.yml` | CKAD, CKS, CNPE |
| SBOM, signature and manifest scanners on WSL/macOS | `setup/hosts/controller_tools.yml` | CKS, CNPE |
| CNI and native RBAC, admission, Secrets, jobs and scheduling APIs | `setup/kube_cluster.yml` | All Kubernetes profiles |
| Dynamic storage, Ingress and Gateway APIs | `setup/tasks/addons/storage.yml`, `traefik.yml` | CKA, CKAD, CNPE; CKS selects Traefik |
| Node resource metrics for observation and autoscaling | `setup/addons/certification_addons.yml` | CKA, CKAD, CNPE |
| AppArmor, gVisor, Falco, CIS tools and audit logging | `setup/security/`, `setup/tasks/addons/audit.yml` | CKS; CNPE also selects audit logging |
| GitOps, workflows, progressive delivery, telemetry, policy, mesh and platform APIs | `setup/kubernetes_certification.yml`, selected `setup/tasks/addons/` | CNPE |
| Linux administration, storage, directory, networking and virtualization tools | `setup/hosts/linux_foundation.yml`, `setup/vars/linux.yml` | LFCS |
| LAN LoadBalancer controller and pool | `setup/addons/loadbalancer.yml` | Explicit exercise selection with reserved addresses |
| Additional HA control planes and proxy | `setup/hosts/ha_lab.yml`, `setup/ha_certification.yml` | Explicit CKA HA selection |
| Operator installation and custom platform APIs | `setup/tasks/addons/crossplane.yml` through `setup/addons/certification_stack.yml` | CNPE; explicit CKA operator exercise |

The image build check is in `tests/tasks/image_build.yml`. The supply-chain
checks run in both CKS and CNPE and can also run without VMs:

```bash
ansible-playbook tests/controller_practical.yml
```

## CKA

CKA is a hands-on, performance-based exam. The
[official CKA objectives](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/)
cover cluster architecture/installation/configuration 25%, workloads/scheduling
15%, services/networking 20%, storage 10%, and troubleshooting 30%.
Use the CKA profile for a base cluster with metrics, dynamic storage and routing.

### 1. Build and maintain the cluster

**Task:** inspect the kubeadm configuration, container runtime, CNI and node
versions. Explain how a worker joins and how the control plane authenticates it.
Create a namespace-scoped Role and binding, then prove its ServiceAccount can
perform the intended action and cannot administer another namespace. Render
Helm/Kustomize resources. For the operator-installation objective, the existing
Crossplane installer provides a pinned operator and composition function:

```bash
ansible-playbook -i setup/inventory setup/addons/certification_stack.yml \
  -e '{"certification_addons":["crossplane"]}'
```

Inspect its CRDs, function health and reconciliation conditions. This is an
explicit exercise selection, like the optional LoadBalancer and HA labs;
the ordinary CKA profile keeps those additional components out of its baseline.
Use a fresh certification run afterwards to return to the profile's original
component selection and remove the exercise's additional controllers and APIs.

**Verify:** all expected nodes are Ready, system workloads are healthy, the
selected context reaches the API, and both RBAC requests produce the expected
result. **Failure drill:** remove a practice binding, diagnose the forbidden
request, restore the narrow permission and repeat it. **Cleanup:** delete the
practice namespace and only the cluster-scoped objects you created.

### 2. Maintain workloads and scheduling

**Task:** perform a rolling update and rollback; consume ConfigMaps/Secrets;
configure requests, limits, probes, affinity and tolerations. Scale an application
with an HPA using the metrics API. Drain one worker, inspect replacement pods,
then uncordon it.

**Verify:** application responses remain correct, new pods satisfy placement,
and HPA reports usable metrics. **Failure drill:** use an unsatisfiable node
selector or oversized request, explain Pending events and correct it. Remove
practice labels/taints and uncordon the worker when finished.

### 3. Route traffic and isolate workloads

**Task:** compare ClusterIP, NodePort and a supported LoadBalancer implementation;
configure Ingress and Gateway API routes; resolve Service names through CoreDNS.
Add namespace-scoped default-deny policy and explicit application/DNS allowances.

**Verify:** inspect EndpointSlices and route conditions, then make real requests
from allowed and denied clients. **Failure drill:** break a Service target port,
then a route backend reference; use events and endpoint evidence to distinguish
them from a DNS or policy failure. Restore each declaration before moving on.
LoadBalancer exposure requires a provider/controller; pending external addresses
alone do not prove application failure.

For local LAN LoadBalancer practice, reserve unused addresses outside DHCP and
declare them in an ignored file such as `artifacts/practice/metallb.yml` under
`metallb_addresses` (a YAML list of address ranges or CIDRs). Install the controller:

```bash
ansible-playbook -i setup/inventory setup/addons/loadbalancer.yml \
  -e @artifacts/practice/metallb.yml
```

The installer has no guessed address pool and leaves automatic assignment off.
It runs `tests/loadbalancer.yml` to verify allocation and HTTP traffic from the
controller, then removes that test's namespace and Service.
Annotate only the exercise Service with
`metallb.io/address-pool: practice` and use `type: LoadBalancer`. Verify its
allocated address with a real request from WSL. Remove the exercise Service
before removing its pool. Pluralsight may provide its own LoadBalancer
implementation; use that provider's declared networking instead of LAN ARP.

### 4. Provision and recover storage

**Task:** compare static PVs with dynamic claims, access modes and reclaim
policies. Write a unique marker, replace the consumer and verify persistence.
Use a disposable claim for deletion/reclaim experiments.

**Failure drill:** select an unavailable StorageClass or mismatched access mode,
diagnose claim events and correct the request. **Cleanup:** remove consumers
before their claims and verify the intended reclaim behaviour.

### 5. Troubleshoot and rehearse recovery

**Task:** diagnose a failed workload through events, current/previous logs,
resource metrics and runtime/node logs. On a disposable worker, stop kubelet,
identify the resulting node condition, restart it and verify recovery. Rehearse
a version-compatible kubeadm upgrade one node at a time using the matching
Kubernetes upgrade instructions and the profile's release pins.

**Verify:** save and validate an authenticated etcd snapshot, then restore it
into an isolated directory. The automated CKA check does that isolated restore;
it does not replace the live database or prove full disaster recovery. Practise
replacing live data only in a deliberately disposable environment. Remove the
test snapshot/restore directory and confirm node and application health.

### Optional high availability topology

HA control-plane setup belongs to CKA. Its provisioning is retained in
`setup/hosts/ha_lab.yml`, `setup/ha_certification.yml` and `inventories/ha.ini`.
Use the dedicated HA recipe in the [certification guide](certifications.md) when
that exercise is selected. Multiple control planes enable the separate quorum
and API failover checks. A normal CKA run does not require creating those extra
VMs, and the single-control-plane checks do not establish HA readiness.

## CKAD

The [official CKAD objectives](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/)
weight build/design 20%, deployment 20%, observation/debugging 15%,
environment/security 25%, and networking 20%.

### 1. Build and deliver an application

**Goal:** create a small HTTP image, run two replicas and serve a unique response.
The CKAD profile installs Buildah on the first worker, so the build exercise
uses the same Kubernetes lab. Connect to that worker with the shared SSH key.
Create a build directory and a Dockerfile based on
`busybox:1.37.0` which places a marker in `/www/index.html` and runs
`httpd -f -p 8080 -h /www`.

**Build and export, on the worker:** use the exact image name in both commands.
Buildah uses a separate storage driver and does not reconfigure containerd.

```bash
sudo buildah --storage-driver vfs bud --isolation chroot --network host \
  -t docker.io/library/ckad-web:lab /var/tmp/ckad-build
sudo buildah --storage-driver vfs push docker.io/library/ckad-web:lab \
  docker-archive:/var/tmp/ckad-web.tar:docker.io/library/ckad-web:lab
```

Retrieve the archive from the builder to the controller's ignored
`artifacts/practice/ckad-web.tar`. For the home inventory, run on WSL:

```bash
ansible 192.168.101.34 -b -m ansible.builtin.fetch \
  -a 'src=/var/tmp/ckad-web.tar dest=artifacts/practice/ckad-web.tar flat=true'
```

Use the selected inventory's first worker address for cloud labs.

Import a saved archive into each selected Kubernetes node with Ansible:

```bash
ansible cluster_nodes -b -m ansible.builtin.copy \
  -a 'src=artifacts/practice/ckad-web.tar dest=/tmp/ckad-web.tar mode=0600'
ansible cluster_nodes -b -m ansible.builtin.command \
  -a 'ctr --namespace k8s.io images import /tmp/ckad-web.tar'
ansible cluster_nodes -b -m ansible.builtin.file \
  -a 'path=/tmp/ckad-web.tar state=absent'
```

Use the imported image's exact name and `imagePullPolicy: Never` for that local
exercise. Alternatively, use your own registry and a digest-pinned image.
**Verify:** run two replicas with resource limits and request the HTTP marker
through their Service. The automated image check also builds, exports, imports
and executes an image, then removes its unique image and temporary archives.

**Failure drill:** select an unavailable tag, inspect pod events and correct
the image reference. **Cleanup:** delete only the exercise namespace and remove
the temporary image when no practice workload uses it.

### 2. Configure and secure a multi-container workload

**Task:** an init container writes a file to `emptyDir`; an application reads it
and consumes a ConfigMap and Secret. Add a companion container that reads the
same file. Run as a non-root UID, disable automatic service-account token mounts,
drop capabilities, and specify resource requests and limits.

**Verify:** inspect each container's logs; use `kubectl exec` to check the shared
file and effective UID. Check that the expected configuration is consumed without
printing secret values into retained logs.

**Failure drill:** use the wrong Secret key or make the init container exit with
an error. Explain the difference between configuration errors and init failures,
repair the workload, and verify completion/readiness. **Cleanup:** delete the
namespace, including its ConfigMaps and Secrets.

### 3. Control a rollout and repair health checks

**Task:** deploy two replicas with startup, readiness and liveness probes. Change
the application response through a rolling update; examine its history and
perform an undo. Repeat a traffic switch with separate blue and green Deployments.
Render a Helm chart and a Kustomize overlay, then compare their resulting objects.

```bash
kubectl -n practice-ckad rollout status deployment/web --timeout=180s
kubectl -n practice-ckad rollout history deployment/web
kubectl -n practice-ckad get pods,events
kubectl -n practice-ckad logs deployment/web --all-containers
```

**Verify:** make requests through the Service and observe the expected revision;
inspect ready EndpointSlices, not only Deployment status. **Failure drill:**
give readiness the wrong port, diagnose the empty ready-backend set, and repair it.
**Cleanup:** remove releases and the exercise namespace.

### 4. Make application data survive replacement

**Task:** request a PVC from `local-path`, mount it into a workload, write a unique
marker, then replace the pod. Compare that result with `emptyDir`.
**Verify:** the new pod reads the same marker; inspect PVC, PV, StorageClass and
pod events. **Failure drill:** select a nonexistent StorageClass, diagnose the
Pending claim, and correct it. **Cleanup:** remove consumers before deleting the
PVC; verify that the disposable PV is reclaimed.

### 5. Diagnose service and network-policy failures

**Task:** expose the application with a Service and an Ingress. Add default-deny
policy, then permit only a labelled client and the DNS traffic it needs.
**Verify:** an allowed client reaches HTTP, an unlabelled client cannot, and
name resolution works. Inspect selectors, target ports and EndpointSlices.
**Failure drill:** change the Service selector and distinguish that failure from
policy denial. Restore it and repeat both positive and negative requests.
**Cleanup:** delete only the exercise namespace and its routes.

### 6. Extend and troubleshoot the application environment

Practise Jobs/CronJobs, quotas/LimitRanges, ServiceAccounts/RBAC, and discovering
an installed CRD such as the routing APIs. Submit an over-quota request and prove
admission rejects it; correct the request and verify scheduling. Compare
`kubectl api-resources` with `kubectl explain`; replace a deprecated API in a
local manifest before applying it. Finish by recreating one task from a blank file.

## CKS

The [official CKS curriculum](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)
allocates 15% to cluster setup, 15% to cluster hardening, 10% to host hardening,
20% to workload protections, 20% to supply-chain security and 20% to runtime investigation.

| Drill | Required action | Acceptance condition | Failure and recovery |
| --- | --- | --- | --- |
| Network and API boundaries | Restrict an exercise namespace and test an unprivileged ServiceAccount | Allowed request succeeds; prohibited namespace/resource access fails | Remove an allow rule, identify the missing permission, restore only that rule |
| TLS ingress and binary integrity | Create a SAN-bearing test certificate and TLS Secret, bind an Ingress to it, and verify a published binary digest | HTTPS verifies with the intended CA and hostname; correct digest verifies | Break the Secret/reference or alter a binary copy, then restore the declared input |
| Node endpoint exposure | Inspect listening ports and access to node/metadata endpoints | Only intended paths are reachable from the test workload | Identify and repair an unnecessarily exposed endpoint in the disposable lab |
| Baseline assessment | Run `kube-bench` on the selected node and inspect one finding | Explain evidence, remediation and impact | Apply a narrow correction, rerun that assessment and retain other settings |
| Accounts and upgrades | Minimize ServiceAccount permissions and rehearse a compatible patch upgrade | A limited account cannot perform an administrative action; nodes recover after the upgrade | Diagnose excessive RBAC or a package/version mismatch and restore the declared baseline |
| Kernel confinement | Compare RuntimeDefault seccomp/AppArmor and a gVisor RuntimeClass | Inspect actual process confinement and sandbox kernel output | Use an invalid runtime/profile, inspect events, restore the working selection |
| Workload isolation | Enforce restricted admission, disable privilege escalation and use read-only roots | An unsafe pod is rejected; a compliant workload runs | Supply a writable `emptyDir` for an application that legitimately needs temporary files |
| Secrets and tenants | Scope secret access and isolate namespaces | A different tenant cannot read or mount the secret | Correct an overbroad RoleBinding and repeat both tests |
| Encrypted workload traffic | Configure strict Istio mutual TLS between injected workloads | Meshed clients succeed; an incompatible unmeshed client is rejected | Inspect injection and policy before changing transport security |
| Delivery integrity | Use the prepared Buildah client to compare image footprints; produce an SBOM, inspect an image and validate a signature | Identify dependencies; verify the approved artifact; reject tampering | Correct the artifact/reference rather than bypassing verification |
| Registry admission | Use the native ValidatingAdmissionPolicy API to scope an allowed-registry rule to the practice namespace | An unapproved image reference is rejected and an allowed one is accepted | Correct the image/rule; remove its binding and policy after the drill |
| Static analysis | Run KubeLinter and Trivy against a deliberately unsafe exercise manifest | Required findings disappear after correcting the workload | Remove privilege, pin the image and define appropriate limits |
| Runtime investigation | Generate a uniquely named write in a disposable container | Falco records that exact activity on the actual workload node | Map pod → node → runtime evidence; remove only the test file/workload |
| Audit trail | Make a labelled API request and locate its audit event | Actor, verb and resource are identifiable without secret bodies | Fix the narrow policy or log path and repeat the request |

The CKS profile prepares audit logging, AppArmor, gVisor, Falco and kube-bench.
The automated runtime checks are in `tests/tasks/cks.yml`; the shared negative
RBAC, admission and network cases are in `tests/tasks/kcsa.yml`. Do not change
the real controller's SSH/firewall while practising host hardening: use the lab node.

### Supply-chain exercise without publishing an artifact

Use a small project directory or a saved image archive as the SBOM input:

```bash
umask 077
mkdir -p artifacts/practice
syft docker-archive:artifacts/practice/ckad-web.tar -o cyclonedx-json \
  > artifacts/practice/sbom.json
kube-linter lint artifacts/practice/manifests
TRIVY_CACHE_DIR="$PWD/artifacts/practice/trivy-cache" \
  trivy config --skip-check-update artifacts/practice/manifests
```

Inspect findings, repair the manifest and rerun. For image vulnerabilities,
use `trivy image` against the selected image and its downloaded database;
configuration scanning alone is not a vulnerability scan.

For a local Cosign 3 signing exercise, create disposable test keys and an explicit
local-only signing configuration. This exercise deliberately uses no public
transparency service; its verification checks the local public key and artifact.

```bash
COSIGN_PASSWORD='' cosign generate-key-pair --output-key-prefix artifacts/practice/lab-key
cosign signing-config create --no-default-fulcio --no-default-oidc \
  --no-default-rekor --no-default-tsa --out artifacts/practice/local-signing.json
COSIGN_PASSWORD='' cosign sign-blob --key artifacts/practice/lab-key.key \
  --signing-config artifacts/practice/local-signing.json \
  --bundle artifacts/practice/sbom.bundle.json artifacts/practice/sbom.json
cosign verify-blob --key artifacts/practice/lab-key.pub \
  --bundle artifacts/practice/sbom.bundle.json --insecure-ignore-tlog \
  artifacts/practice/sbom.json
```

Copy the SBOM, alter the copy and verify that the same bundle rejects it.
Remove the disposable key, bundle and exercise output afterwards. Public image
signing and admission verification are separate exercises using your own registry
and its chosen trust policy. Never commit private keys or registry credentials.

## CNPE

The [official CNPE objectives](https://training.linuxfoundation.org/certification/certified-cloud-native-platform-engineer-cnpe/)
weight architecture 15%, GitOps/delivery 25%, self-service APIs 25%, operations 20%,
and security/governance 15%. Practise terminal operations and the selected web
interfaces; read their current URLs and credentials from `artifacts/access/`.

| Scenario | Task and proof of success | Deliberate failure and recovery |
| --- | --- | --- |
| Tenant onboarding | Create a namespace, scoped roles, a LimitRange and a quota. Prove tenant requests are bounded and another tenant is inaccessible. | Submit an oversized request; diagnose admission, then right-size it. |
| Platform routing/storage | Publish an HTTP application through a route and retain data through pod replacement. Verify both request traffic and a persisted marker. | Break a selector or volume binding and recover the same application/data. |
| Capacity and cost | Inspect Prometheus/Grafana CPU, memory and request information; justify a smaller or larger allocation. | Create a limit-driven failure in the exercise namespace; adjust the responsible resource and measure recovery. |
| GitOps recovery | Deliver an application from a practice Git repository; inspect sync and actual application response. | Create drift and then a bad desired revision. Explain self-healing versus rollback and restore a known-good revision. |
| Pipeline delivery | Execute an Argo workflow with dependencies and output passing; inspect logs and resulting artifacts. | Fail one step, trace its dependants, correct the declared input and rerun. |
| Progressive release | Promote and abort an Argo Rollout; check traffic and stable/new ReplicaSets. | Supply a failing analysis signal and verify that stable traffic survives. |
| Platform API | Define a namespaced Crossplane API with schema validation and a composition. Submit a request and inspect the produced resource. | Submit invalid input, then break composition output and use conditions/events to recover it. |
| Developer portal | Inspect Backstage ownership and execute its supplied template. Extend a template/action in the development workspace for a new request flow. | Break a catalog reference or template input, inspect backend/task logs, and repair it. |
| Telemetry incident | Trace an application through Collector output, metrics, a recording rule and an alert. | Break one exporter/receiver input; identify the failed hop and restore the signal. |
| Policy and identity | Create a namespace-scoped Kyverno validation/mutation exercise and least-privilege access. | Prove unsafe admission and unauthorized requests fail; repair only the policy/input that caused the failure. |
| Service security | Demonstrate Istio transport protection and inspect the mesh in Kiali. | Compare an allowed mesh request with an incompatible client and recover the client/policy. |
| Governance pipeline | Generate an SBOM, run scanners, verify a signature, and retain bounded audit evidence. | Fail a quality gate or signature check, correct the source artifact and rerun the pipeline. |

CNPE selects the supply-chain clients, the worker image builder and bounded audit
logging in its profile. For an existing lab, rerun the matching profile to reconcile
those prerequisites without rebuilding its VMs. To reconcile only audit settings:

```bash
ansible-playbook -i setup/inventory setup/addons/certification_stack.yml \
  -e '{"certification_addons":["audit"]}'
```

This reconciles the audit settings and waits for the API server; it does not
rebuild VMs. The standard Backstage template records a request with `debug:log`;
it does not provision a Crossplane object automatically. Connecting those
systems is a development exercise, with Node/Corepack/Yarn prepared by the profile.

`tests/tasks/cnpe.yml` combines working delivery, storage/routing, monitoring,
workflow, rollout, telemetry, policy, Crossplane, Backstage and Istio checks.
Run the full environment checks after a scenario, then delete only your practice
namespace and any uniquely named cluster-scoped API/policy objects you created.

## Verify, reset and clean up

For any selected Kubernetes profile:

```bash
ansible-playbook -i setup/inventory tests/certification.yml \
  -e @profiles/certifications/ckad.yml
```

Change the profile for CKA, CKS or CNPE. The Linux equivalent is in the
[Linux guide](linux-certifications.md#verify-and-repeat). Reconcile the profile
to repair its managed baseline; use a fresh VM run for a deliberate full reset.
Inspect the generated report's actual executed checks rather than treating a
profile name as proof that every syllabus exercise was completed.

To stop and destroy both Linux labs and remove their disposable caches:

```bash
ansible-playbook -i inventories/lfcs.ini setup/maintenance/linux_cleanup.yml
```

On Windows, run that playbook through the launch option in the Linux guide with
`-LabPlaybook setup/maintenance/linux_cleanup.yml`. For completed controller
downloads and Python package caches, use:

```bash
ansible-playbook setup/maintenance/controller_cleanup.yml
```

Cleanup preserves source code, the shared SSH key and private verification reports.
Base-box removal refuses to force removal of a box still used by another VM.
To finish with every local lab VM, including the Kubernetes nodes, select
`setup/maintenance/lab_cleanup.yml` instead of `linux_cleanup.yml`.
On Windows, pass that playbook to the same privileged launch command.
