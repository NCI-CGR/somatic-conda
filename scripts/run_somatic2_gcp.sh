#!/bin/sh

cmd="qsub -q all.q  -v PATH -cwd -j y -S /bin/sh -o ${PWD} ${PWD}/somatic2_wrapper.sh ${PWD}/config.yaml"

echo "Command run: $cmd"
eval $cmd



