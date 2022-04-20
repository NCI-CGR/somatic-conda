#!/bin/sh

# module list
module load  sge singularity/3.0.1

# cmd="unset module; qsub -q long.q -V -j y -S /bin/sh -o ${PWD} ${PWD}/somatic2_wrapper.sh ${PWD}/config.yaml; source /etc/profile.d/modules.sh"
# cmd="sbatch -p norm -t 200:00:00 --export=ALL --mem=32g -o ${PWD}/somatic_wrapper.sh.o%j --wrap='${PWD}/somatic_conda_wrapper_biowulf.sh ${PWD}/config.yaml' "

###  -l h_rt=240:00:00 seems keep the job in "qw" state 
cmd="qsub -q all.q  -v PATH -v TMPDIR -cwd -j y -S /bin/sh  -o ${PWD} ${PWD}/somatic_conda_wrapper_ccad.sh ${PWD}/config.yaml"

echo "Command run: $cmd"
eval $cmd



