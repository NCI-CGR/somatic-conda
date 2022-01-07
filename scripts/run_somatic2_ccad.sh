#!/bin/sh

# module list
module load  sge 

# cmd="unset module; qsub -q long.q -V -j y -S /bin/sh -o ${PWD} ${PWD}/somatic2_wrapper.sh ${PWD}/config.yaml; source /etc/profile.d/modules.sh"
cmd="qsub -q all.q  -v PATH -cwd -j y -S /bin/sh -o ${PWD} ${PWD}/somatic2_wrapper.sh ${PWD}/config.yaml"

echo "Command run: $cmd"
eval $cmd



