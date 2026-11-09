#!/bin/sh
set -eu
repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repository_root"
count=0
for inventory in setup/inventory inventories/pluralsight.ini.example; do
    for playbook in setup/*.yml setup/cluster/*.yml setup/addons/*.yml setup/security/*.yml setup/hosts/*.yml setup/maintenance/*.yml; do
        ansible-playbook -i "$inventory" "$playbook" --syntax-check >/dev/null
        count=$((count + 1))
    done
done
for profile in profiles/certifications/*.yml; do
    inventory=setup/inventory
    case "${profile##*/}" in
        lfcs.yml) inventory=inventories/lfcs.ini ;;
        lfca.yml) inventory=inventories/lfca.ini ;;
    esac
    ansible-playbook -i "$inventory" setup/certification_lab.yml -e "@$profile" --syntax-check >/dev/null
    ansible-playbook -i "$inventory" setup/fresh_certification.yml -e "@$profile" --syntax-check >/dev/null
    count=$((count + 2))
done
for playbook in setup/hosts/ha_lab.yml setup/hosts/ha_cleanup.yml; do
    ansible-playbook -i inventories/ha.ini "$playbook" --syntax-check >/dev/null
    count=$((count + 1))
done
ansible-playbook -i inventories/cca.ini setup/hosts/cca_lab.yml --syntax-check >/dev/null
ansible-playbook -i inventories/mesh.ini setup/cluster/mesh_cluster.yml -e @profiles/cilium-mesh.yml --syntax-check >/dev/null
count=$((count + 2))
printf '%s syntax checks passed\n' "$count"
ansible-lint --offline
ansible-playbook -i localhost, -c local tests/validation.yml
