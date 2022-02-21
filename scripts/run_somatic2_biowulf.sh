#!/bin/sh

# module list
module load snakemake/5.19.0

# cmd="unset module; qsub -q long.q -V -j y -S /bin/sh -o ${PWD} ${PWD}/somatic2_wrapper.sh ${PWD}/config.yaml; source /etc/profile.d/modules.sh"
cmd="sbatch -p norm -t 200:00:00 --export=ALL --mem=32g -o ${PWD}/somatic_wrapper.sh.o%j --wrap='${PWD}/somatic2_wrapper_biowulf.sh ${PWD}/config.yaml' "

echo "Command run: $cmd"
eval $cmd



