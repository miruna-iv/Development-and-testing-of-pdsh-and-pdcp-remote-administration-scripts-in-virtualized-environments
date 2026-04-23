#!/bin/bash
BASE_VM="$1"
COUNT="$2"

if [ -z "$BASE_VM" ] || [ -z "$COUNT" ]; then
    echo "Utilizare: $0 <nume_vm_sursa> <nr_copii>"
    exit 1
fi


for i in $(seq 1 $COUNT); do
    NEW_VM="${BASE_VM}${i}"
    virt-clone --original "$BASE_VM" --name "$NEW_VM" --auto-clone --check all=off
    if [ $? -ne 0 ]; then
        echo "EROARE FATALA: Clonarea a esuat pentru $NEW_VM. Opresc scriptul."
        exit 1
    fi
    virt-customize -d "$NEW_VM" --hostname "$NEW_VM"
    virsh start "$NEW_VM"
done
