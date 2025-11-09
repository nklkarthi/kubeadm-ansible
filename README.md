# Kubeadm Ansible

This repository contains Ansible playbooks to set up a Kubernetes cluster using `kubeadm`. All playbooks are designed to be reusable across different cloud environments and user configurations.

## Prerequisites

*   Ansible installed on your local machine.
*   An SSH key pair. This guide assumes you have a key at `~/.ssh/id_acg.pub`.
*   Three servers with a user account (default: `cloud_user`).

## Configuration Variables

The playbooks support the following variables for customization:

- `target_user`: User account name (default: `cloud_user`)
- `timezone`: System timezone (default: `UTC`)
- `gitea_target_host`: Specific host for Gitea installation (default: second worker node)

### Example with custom variables:
```bash
ansible-playbook -i setup/inventory setup/playbook.yml \
  -e "target_user=ubuntu" \
  -e "timezone=America/New_York"
```

## SSH Setup

Copy your SSH public key to each of the servers. Replace hostnames and user as needed for your environment.

```bash
ssh-copy-id -i ~/.ssh/id_acg.pub cloud_user@your-master-node.com
ssh-copy-id -i ~/.ssh/id_acg.pub cloud_user@your-worker1-node.com
ssh-copy-id -i ~/.ssh/id_acg.pub cloud_user@your-worker2-node.com
```

## Inventory Configuration

Update `setup/inventory` with your server hostnames:

```ini
[cloud_servers]
your-master-node.com ansible_user=cloud_user
your-worker1-node.com ansible_user=cloud_user
your-worker2-node.com ansible_user=cloud_user

[master]
your-master-node.com ansible_user=cloud_user

[workers]
your-worker1-node.com ansible_user=cloud_user
your-worker2-node.com ansible_user=cloud_user
```

## Ansible Setup

Run the following Ansible playbooks in order to provision the servers and set up the Kubernetes cluster.

1.  **Visudoers:** This playbook configures sudo access for the `cloud_user`.

    ```bash
    ansible-playbook -i setup/inventory setup/visudoers.yml --ask-become-pass
    ```

2.  **Bash-it:** This playbook installs and configures Bash-it, a shell framework.

    ```bash
    ansible-playbook -i setup/inventory setup/bash-it.yml
    ```

3.  **Firewall:** This playbook configures the firewall on the servers.

    ```bash
    ansible-playbook -i setup/inventory setup/firewall.yml
    ```

4.  **Kube Dependencies:** This playbook installs the dependencies required for Kubernetes.

    ```bash
    ansible-playbook -i setup/inventory setup/kube_dependencies.yml
    ```

5.  **Kube Master:** This playbook initializes the Kubernetes master node.

    ```bash
    ansible-playbook -i setup/inventory setup/kube_master.yml
    ```

6.  **Kube Workers:** This playbook joins the worker nodes to the cluster.

    ```bash
    ansible-playbook -i setup/inventory setup/kube_workers.yml
    ```

7.  **Gitea (Optional):** This playbook installs Gitea on worker node 737f3fac482c.mylabserver.com.

    ```bash
    ansible-playbook -i setup/inventory setup/gitea.yml
    ```

8.  **Get Internal IPs (Utility):** Get internal IP addresses for ArgoCD integration.

    ```bash
    ansible-playbook -i setup/inventory setup/get-internal-ips.yml
    ```

## Services

- **Kubernetes Cluster**: Master node with worker nodes ready for deployments
- **Gitea**: Git service with web interface accessible on port 3000 (if installed)

## Access Information

- **Kubernetes**: Use `kubectl` from the master node
- **Gitea**: Access via `http://[gitea-host]:3000` (if installed)

## ArgoCD Integration

When integrating Gitea with ArgoCD:

1. **Get internal IP**: Run `ansible-playbook -i setup/inventory setup/get-internal-ips.yml`
2. **Use internal IP address** in ArgoCD repository configuration
3. **Repository URL format**: `http://[internal-ip]:3000/username/repo.git`
4. **Why**: ArgoCD pods need direct internal network access, external hostnames cause routing timeouts

### Quick Command:
```bash
# Get the internal IP for ArgoCD
ansible-playbook -i setup/inventory setup/get-internal-ips.yml
```

## Reusability for New Cloud Environments

These playbooks are designed to work with temporary cloud servers (e.g., 14-day lab environments). When you get new servers:

1. Update the `setup/inventory` file with new hostnames
2. Run the same playbooks without modification
3. Use variables to customize user accounts and settings as needed

No hardcoded values will break when switching to new cloud servers.