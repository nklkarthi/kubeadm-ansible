require "shellwords"

public_key_path = ENV.fetch("VAGRANT_LAB_PUBLIC_KEY", File.join(__dir__, "artifacts/vagrant/id_ed25519.pub"))
public_key = File.read(public_key_path).strip
ubuntu_box = "bento/ubuntu-24.04"
ubuntu_version = "202510.26.0"
bridge = ENV.fetch("VAGRANT_LAB_BRIDGE", "en0")
selected_provider = ENV.fetch("VAGRANT_DEFAULT_PROVIDER", "virtualbox")
state_directory = ENV.fetch("VAGRANT_DOTFILE_PATH", File.join(__dir__, ".vagrant"))
access_directory = ENV.fetch("VAGRANT_LAB_ACCESS_DIR", File.join(__dir__, "artifacts/vagrant/access"))

nodes = {
  "master" => { ip: "192.168.101.32", memory: 4096, primary: true },
  "worker-01" => { ip: "192.168.101.34", memory: 4096, primary: true },
  "worker-02" => { ip: "192.168.101.35", memory: 4096, primary: true },
  "ha-01" => { ip: "192.168.101.37", memory: 2048 },
  "ha-02" => { ip: "192.168.101.38", memory: 2048 },
  "mesh-01" => { ip: "192.168.101.39", memory: 2048 },
  "lfcs" => { ip: "192.168.101.40", memory: 2048, hostname: "lfcs-lab",
              box: "almalinux/10", box_version: "10.2.20260914" }
}

Vagrant.configure("2") do |config|
  config.vm.box = ubuntu_box
  config.vm.box_version = ubuntu_version
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.boot_timeout = 300

  nodes.each do |name, settings|
    config.vm.define name, autostart: settings.fetch(:primary, false) do |node|
      node.vm.hostname = settings.fetch(:hostname, "kube-#{name}")
      if settings[:box]
        node.vm.box = settings[:box]
        node.vm.box_version = settings[:box_version]
      end
      machine_id = File.join(state_directory, "machines", name, selected_provider, "id")
      access_marker = File.join(access_directory, "#{name}-#{selected_provider}.id")
      if File.file?(machine_id) && File.file?(access_marker) && File.read(machine_id).strip == File.read(access_marker).strip
        node.ssh.username = "vboxuser"
        node.ssh.private_key_path = ENV.fetch("VAGRANT_LAB_PRIVATE_KEY", File.join(__dir__, "artifacts/vagrant/id_ed25519"))
        node.ssh.insert_key = false
      end
      node.vm.provider "virtualbox" do |provider, override|
        override.vm.network "public_network", ip: settings[:ip], bridge: bridge
        if ENV["VAGRANT_LAB_SSH_HOST"]
          override.ssh.host = ENV["VAGRANT_LAB_SSH_HOST"]
          override.vm.network "forwarded_port", guest: 22, host: 2222,
                              host_ip: ENV["VAGRANT_LAB_SSH_HOST"], id: "ssh", auto_correct: true
        end
        provider.name = "kubeadm-#{name}"
        provider.cpus = 2
        provider.memory = settings[:memory]
        provider.gui = false
        provider.linked_clone = true
        provider.customize ["modifyvm", :id, "--rtcuseutc", "on", "--vram", "16", "--audio-enabled", "off"]
      end
      node.vm.provider "hyperv" do |provider, override|
        override.vm.box = settings.fetch(:box, "gusztavvargadr/ubuntu-server-2404-lts")
        override.vm.box_version = settings.fetch(:box_version, "2607.0.0")
        override.vm.network "public_network", bridge: bridge
        provider.vmname = "kubeadm-#{name}"
        provider.cpus = 2
        provider.memory = settings[:memory]
        provider.linked_clone = true
        provider.enable_checkpoints = false
        provider.enable_automatic_checkpoints = false
        provider.enable_virtualization_extensions = true if name == "lfcs"
      end
      node.vm.provision "shell", privileged: true, upload_path: "/tmp/kubeadm-lab-provision.sh", inline: <<~SHELL
        set -eu
        trap 'rm -f "$0"' EXIT
        rm -f /tmp/vagrant-shell
        install -d -m 0755 /var/lib/kubeadm-lab
        if [ ! -f /var/lib/kubeadm-lab/ssh-identity ]; then
          rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub
          ssh-keygen -A
          systemctl reload ssh.service 2>/dev/null || systemctl reload sshd.service
          touch /var/lib/kubeadm-lab/ssh-identity
        fi
        id -u vboxuser >/dev/null 2>&1 || useradd --create-home --shell /bin/bash vboxuser
        install -d -m 0700 -o vboxuser -g vboxuser /home/vboxuser/.ssh
        printf '%s\\n' #{Shellwords.escape(public_key)} > /home/vboxuser/.ssh/authorized_keys
        chown vboxuser:vboxuser /home/vboxuser/.ssh/authorized_keys
        chmod 0600 /home/vboxuser/.ssh/authorized_keys
        printf '%s\\n' 'vboxuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-vboxuser
        chmod 0440 /etc/sudoers.d/90-vboxuser
        visudo -cf /etc/sudoers.d/90-vboxuser
        timedatectl set-timezone Asia/Singapore
        if [ "$(timedatectl show --property=CanNTP --value)" != yes ]; then
          if command -v apt-get >/dev/null 2>&1; then
            apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends systemd-timesyncd
          else
            dnf install -y chrony
            systemctl enable --now chronyd
          fi
        fi
        timedatectl set-ntp true
      SHELL
      if selected_provider == "hyperv"
        node.vm.provision "shell", privileged: true, upload_path: "/tmp/kubeadm-lab-provision.sh", inline: <<~SHELL
          set -eu
          trap 'rm -f "$0"' EXIT
          interface=$(ip -4 route show default | awk '{print $5; exit}')
          gateway=$(ip -4 route show default | awk '{print $3; exit}')
          test -n "$gateway"
          if systemctl is-active --quiet NetworkManager; then
            connection=$(nmcli -g GENERAL.CONNECTION device show "$interface")
            dns=$(nmcli -g IP4.DNS device show "$interface" | paste -sd,)
            test -n "$dns"
            old_network=$(nmcli -g ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns connection show "$connection")
            nmcli connection modify "$connection" ipv4.method manual ipv4.addresses #{settings[:ip]}/24 ipv4.gateway "$gateway" ipv4.dns "$dns"
            new_network=$(nmcli -g ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns connection show "$connection")
            if [ "$old_network" != "$new_network" ]; then touch /run/kubeadm-lab-reboot; fi
          else
            dns=$(resolvectl dns "$interface" | sed -n 's/^.*: //p')
            test -n "$dns"
            network_file=$(LC_ALL=C networkctl status --no-pager "$interface" | sed -n 's/.*Network File: //p')
            test -n "$network_file"
            dropin="/etc/systemd/network/$(basename "$network_file").d"
            install -d -m 0755 "$dropin"
            network_setting=$(mktemp)
            printf '[Network]\\nDHCP=no\\nAddress=#{settings[:ip]}/24\\nGateway=%s\\nDNS=\\nDNS=%s\\n' "$gateway" "$dns" > "$network_setting"
            if ! cmp -s "$network_setting" "$dropin/90-kubeadm-lab.conf"; then
              install -m 0644 "$network_setting" "$dropin/90-kubeadm-lab.conf"
              touch /run/kubeadm-lab-reboot
            fi
            rm -f "$network_setting"
          fi
          if ! ip -4 address show dev "$interface" | grep -Fq ' #{settings[:ip]}/24 '; then
            ip address add #{settings[:ip]}/24 dev "$interface"
          fi
        SHELL
      end
      unless settings[:box] == "almalinux/10"
      grub_cleanup = <<~'GRUB'
        GRUB_CMDLINE_LINUX="$(printf '%s\n' "$GRUB_CMDLINE_LINUX" | sed -E 's/(^|[[:space:]])autoinstall([[:space:]]|$)/ /g; s/(^|[[:space:]])ds=nocloud-net[^[:space:]]*/ /g')"
        GRUB_CMDLINE_LINUX_DEFAULT="$(printf '%s\n' "$GRUB_CMDLINE_LINUX_DEFAULT" | sed -E 's/(^|[[:space:]])autoinstall([[:space:]]|$)/ /g; s/(^|[[:space:]])ds=nocloud-net[^[:space:]]*/ /g')"
      GRUB
      grub_setting = grub_cleanup
      node.vm.provision "shell", privileged: true, upload_path: "/tmp/kubeadm-lab-provision.sh", inline: <<~SHELL
        set -eu
        trap 'rm -f "$0"' EXIT
        install -d -m 0755 /etc/default/grub.d
        printf '%s\\n' #{Shellwords.escape(grub_setting)} > /tmp/kubeadm-grub.cfg
        if ! cmp -s /tmp/kubeadm-grub.cfg /etc/default/grub.d/99-kubeadm-lab.cfg; then
          install -m 0644 /tmp/kubeadm-grub.cfg /etc/default/grub.d/99-kubeadm-lab.cfg
          update-grub
          touch /run/kubeadm-lab-reboot
        fi
        rm -f /tmp/kubeadm-grub.cfg
      SHELL
      end
    end
  end
end
