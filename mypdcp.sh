#!/bin/bash

# verificare de sanitate
if ! command -v scp &> /dev/null; then
    echo "EROARE (Sanity Check): Comanda scp nu este instalata."
    exit 1
fi

expand_nodes() {
    echo $1 | sed 's/\[\([0-9]*\)-\([0-9]*\)\]/{\1..\2}/g' | xargs -I {} bash -c "eval echo {}"
}

nodes_include=""
nodes_exclude=""
files=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -w) nodes_include=$(expand_nodes "$2"); shift 2 ;;
        -x) nodes_exclude=$(expand_nodes "$2"); shift 2 ;;
        *)  files+=("$1"); shift ;;
    esac
done

dest=${files[-1]}
unset 'files[${#files[@]}-1]'

if [ ${#files[@]} -eq 0 ]; then
    echo "EROARE (Sanity Check): Nu ati specificat fisiere pentru copiere."
    exit 1
fi

final_nodes=""
for n in $nodes_include; do
    if [[ ! " $nodes_exclude " =~ " $n " ]]; then
        final_nodes="$final_nodes $n"
    fi
done

# Functie pentru copiere si verificare consistenta
copy_and_verify() {
    local node=$1
    local file_src=$2
    local dest_path=$3

    echo "[Start $node] Copiez $file_src..."
    scp -o ConnectTimeout=5 "$file_src" "$node:$dest_path"
    if [ $? -eq 0 ]; then
        # veificarea consistentei 
        local_md5=$(md5sum "$file_src" | awk '{print $1}')
        filename=$(basename "$file_src")
        if [[ "$dest_path" == */ ]]; then
             full_remote_path="${dest_path}${filename}"
        else
             full_remote_path="$dest_path"
        fi

        remote_md5=$(ssh -o ConnectTimeout=5 "$node" "md5sum $full_remote_path" | awk '{print $1}')

        if [ "$local_md5" == "$remote_md5" ]; then
            echo "[Verificare $node] SUCCES: Hash MD5 identic. Integritate validata."
        else
            echo "[Verificare $node] EROARE: Hash-urile difera! Fisier corupt."
        fi
    else
        echo "[Eroare $node] Copierea a esuat."
    fi
}

echo "--- Incepem copierea si verificarea ---"
time {
    for node in $final_nodes; do
        for f in "${files[@]}"; do
            copy_and_verify "$node" "$f" "$dest" &
        done
    done
    wait
}

echo "--- Proces finalizat. ---"
