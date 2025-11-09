# Kubeadm Ansible

This repository contains Ansible playbooks to set up a Kubernetes cluster using `kubeadm`.

## Prerequisites

*   Ansible installed on your local machine.
*   An SSH key pair. This guide assumes you have a key at `~/.ssh/id_acg.pub`.
*   Three servers with a user named `cloud_user`.

## SSH Setup

Copy your SSH public key to each of the servers. This will allow Ansible to connect to them without a password.

```bash
ssh-copy-id -i ~/.ssh/id_acg.pub cloud_user@737f3fac481c.mylabserver.com
ssh-copy-id -i ~/.ssh/id_acg.pub cloud_user@737f3fac482c.mylabserver.com
ssh-copy-id -i ~/.ssh/id_acg.pub cloud_user@737f3fac483c.mylabserver.com
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