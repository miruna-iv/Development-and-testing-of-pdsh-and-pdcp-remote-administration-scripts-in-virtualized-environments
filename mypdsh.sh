#!/bin/bash

#verificare de sanitate daca avem ssh instalat
if !command -v ssh &> /dev/null; then
	echo "Eroare (Sanity check): Comanda ssh nu este instalata"
	exit 1
fi

expand_nodes() {
    echo $1 | sed 's/\[\([0-9]*\)-\([0-9]*\)\]/{\1..\2}/g' | xargs -I {} bash -c "eval echo {}"
}

nodes_include=""
nodes_exclude=""
command_to_run=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -w)
            nodes_include=$(expand_nodes "$2")
            shift 2
            ;;
        -x)
            nodes_exclude=$(expand_nodes "$2")
            shift 2
            ;;
        *)
            command_to_run="$1"
            shift
            ;;
    esac
done

#verificare de sanitate: verificam daca am primit comanda de rulat
if [ -z "$command_to_run" ]; then
	echo "Eroare (Sanity check): Nu at specificat nicio comanda de executat"
	exit 1
fi
final_nodes=""
for n in $nodes_include; do
    if [[ ! " $nodes_exclude " =~ " $n " ]]; then
        final_nodes="$final_nodes $n"
    fi
done

user=$(whoami)
time {
	for node in $final_nodes; do
    		actual_cmd=$(echo "$command_to_run" | sed "s/%u/$user/g" | sed "s/%h/$node/g")
    		echo "[Execut pe $node]: $actual_cmd"
   	 	ssh -o ConnectTimeout=5 "$node" "$actual_cmd" &
	done

	wait
}
echo "Toate comenzile au fost finalizate."
