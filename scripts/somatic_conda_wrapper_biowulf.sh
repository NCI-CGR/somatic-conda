#!/bin/sh

echo "Running somatic_conda_wrapper_biowulf.sh ...."


# set -euo pipefail

die() {
    echo "ERROR: $* (status $?)" 1>&2
    exit 1
}



usage="Usage: $0 /path/to/config.yaml"

configFile=""
if [ $# -eq 0 ]; then
    echo "Please specify config file with full path.
$usage"
    exit 1
else 
    configFile=$1
fi

if [ ! -f "$configFile" ]; then
    echo "Config file not found.
$usage"
    exit 1
fi



# LOG_DIR=$(awk -F": " '{if($1=="logDir"){print $2}}' config.yaml | sed "s/'//g")
LOG_DIR=$(awk '($0~/^logDir/){print $2}' $configFile | sed "s/['\"]//g")
execDir=$(awk '($0~/^execDir/){print $2}' $configFile | sed "s/['\"]//g")

LOG_SNAKE=${LOG_DIR}/Snakefile_$(date +%y%m%d)

### Make the required directories
mkdir -p ${LOG_SNAKE} 2>/dev/null


# clusterMode="qsub -v PATH -cwd -q all.q -pe by_node {threads} -o ${LOG_SNAKE}/ -e ${LOG_SNAKE}"
clusterMode='"'"sbatch -p norm -o ${LOG_SNAKE}/slurm-%j.out --cpus-per-task={threads} --mem=40g -e ${LOG_SNAKE}/slurm-j%j.err -t 200:00:00 "'"'

# numJobs=500
numJobs=$(awk '($0~/^maxJobs/){print $2}' $configFile | sed "s/['\"]//g")

latency=120

# snakemake --unlock -s Snakefile

# CMD="module load python3 sge; snakemake -pr --keep-going --rerun-incomplete  --cores 500 --cluster \"$sbcmd\"  --latency-wait 120 all"

# qsub -cwd -q all.q -N run_Snakefile_$(date +%y%m%d) -o ${LOG_DIR}/run_Snakefile_$(date +%y%m%d).stdout -e ${LOG_DIR}/run_Snakefile_$(date +%y%m%d).stderr -b y "$CMD"

cmd="conf=$configFile snakemake --cores $numJobs --skip-script-cleanup --verbose --use-conda  -p -s ${execDir}/workflow/Snakefile.conda_docker --rerun-incomplete --cluster ${clusterMode} --jobs $numJobs --conda-frontend mamba --latency-wait ${latency} --use-singularity &> ${LOG_DIR}/run_Snakefile_$(date +%y%m%d).out"


# module load python3 sge

echo "Command run: $cmd"
eval $cmd 


