#!/bin/sh
set -eu
repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repository_root"
mkdir -p artifacts/vagrant
if [ ! -f artifacts/vagrant/id_ed25519 ]; then
    ssh-keygen -q -t ed25519 -N '' -f artifacts/vagrant/id_ed25519
fi
export VAGRANT_LAB_PUBLIC_KEY="$repository_root/artifacts/vagrant/id_ed25519.pub"
export VAGRANT_LAB_PRIVATE_KEY="$repository_root/artifacts/vagrant/id_ed25519"
export VAGRANT_LAB_ACCESS_DIR="$repository_root/artifacts/vagrant/access"

case "$(uname -s)" in
    Linux)
        if ! command -v brew >/dev/null 2>&1 && [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
            export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
        fi
        if ! brew list --formula hashicorp/tap/vagrant >/dev/null 2>&1; then
            brew install hashicorp/tap/vagrant
        fi
        vagrant_package=$(brew --prefix hashicorp/tap/vagrant)
        vagrant_version=$(brew list --versions hashicorp/tap/vagrant | awk '{print $2}')
        vagrant_runtime="$repository_root/.tools/vagrant-$vagrant_version"
        if [ ! -x "$vagrant_runtime/squashfs-root/AppRun" ]; then
            mkdir -p "$vagrant_runtime"
            (cd "$vagrant_runtime" && "$vagrant_package/bin/vagrant" --appimage-extract >/dev/null)
        fi
        vagrant_binary="$vagrant_runtime/squashfs-root/AppRun"
        if [ -n "${WSL_DISTRO_NAME:-}" ]; then
            export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS=1
            vagrant_windows_home=$(pwsh.exe -NoProfile -NonInteractive -Command '[Environment]::GetFolderPath("UserProfile")' | tr -d '\r')
            vagrant_host_home=$(wslpath -u "$vagrant_windows_home")
            export VAGRANT_DEFAULT_PROVIDER="${VAGRANT_LAB_PROVIDER:-hyperv}"
            vagrant_project="$vagrant_host_home/Vagrant/kubeadm-ansible"
            mkdir -p "$vagrant_project"
            cp Vagrantfile "$vagrant_project/Vagrantfile"
            cp "$VAGRANT_LAB_PUBLIC_KEY" "$vagrant_project/ansible.pub"
            export VAGRANT_CWD="$vagrant_project"
            if [ "$VAGRANT_DEFAULT_PROVIDER" = hyperv ]; then
                export VAGRANT_DOTFILE_PATH="$vagrant_project/.vagrant"
                export VAGRANT_LAB_BRIDGE="${VAGRANT_LAB_BRIDGE:-kubeadm-lab}"
            else
                export VAGRANT_DOTFILE_PATH="$repository_root/artifacts/vagrant/state"
                export VAGRANT_LAB_BRIDGE="${VAGRANT_LAB_BRIDGE:-Realtek PCIe GbE Family Controller #3}"
                export VAGRANT_LAB_SSH_HOST="${VAGRANT_LAB_SSH_HOST:-$(ip -4 route show default | awk '{print $3; exit}')}"
            fi
            export VAGRANT_LAB_PUBLIC_KEY="$vagrant_project/ansible.pub"
            export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
        fi
        ;;
    Darwin)
        if ! command -v vagrant >/dev/null 2>&1; then
            brew install --cask hashicorp/tap/hashicorp-vagrant
        fi
        vagrant_binary=$(command -v vagrant)
        ;;
    *) printf '%s\n' 'Use a macOS or Linux controller with Homebrew.' >&2; exit 1 ;;
esac
if [ "${1:-}" = --state-path ]; then
    printf '%s\n' "${VAGRANT_DOTFILE_PATH:-$repository_root/.vagrant}"
    exit 0
fi
exec "$vagrant_binary" "$@"
