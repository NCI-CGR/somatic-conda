#!/usr/bin/env python3


### Manta: /DCEG/CGF/Bioinformatics/software/manta-1.5.0.centos6_x86_64/bin/configManta.py
### Strelka: /DCEG/CGF/Bioinformatics/software/strelka-2.9.2.centos6_x86_64/bin/configureStrelkaSomaticWorkflow.py

rule run_manta:
    input:
        tumorBam=get_tumor,
        normalBam=get_normal
    output:
        outputDir + '/' + MantaDir + '/{sample}/results/variants/candidateSmallIndels.vcf.gz'
    params:
        exe=MantaExe,
        ref=refGenome,
        outdir=outputDir + '/' + MantaDir + '/{sample}'
    threads:
        4
    log:
        stdout=logdir + '/Snakefile/run_manta_{sample}.stdout',
        stderr=logdir + '/Snakefile/run_manta_{sample}.stderr'
    shell:
        'rm -R {params.outdir};'
        '{params.exe} --normalBam {input.normalBam} --tumorBam {input.tumorBam} --referenceFasta {params.ref} --runDir {params.outdir} --exome > {log.stdout} 2>{log.stderr};'
        'result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) run_manta failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'
        '{params.outdir}/runWorkflow.py -m local -j 8 >> {log.stdout} 2>>{log.stderr};'
        'result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) run_manta failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr}; '
        
rule run_strelka:
    input:
        tumorBam=get_tumor,
        normalBam=get_normal,
        indelCan=outputDir + '/' + MantaDir + '/{sample}/results/variants/candidateSmallIndels.vcf.gz'
    output:
        indel=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels.vcf.gz',
        indelInd=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels.vcf.gz.tbi',    
        snp=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.snvs.vcf.gz'
    params:
        exe=StrelkaExe,
        ref=refGenome,
        outdir=outputDir + '/' + StrelkaDir + '/{sample}'
    threads:
        4
    log:
        stdout=logdir + '/Snakefile/run_strelka_{sample}.stdout',
        stderr=logdir + '/Snakefile/run_strelka_{sample}.stderr'            
    shell:
        'rm -R {params.outdir};'
        '{params.exe} --normalBam {input.normalBam} --tumorBam {input.tumorBam} --referenceFasta {params.ref} --indelCandidates {input.indelCan} --runDir {params.outdir} --exome > {log.stdout} 2>{log.stderr};'
        'result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) run_strelka failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'
        '{params.outdir}/runWorkflow.py -m local -j 8 >> {log.stdout} 2>>{log.stderr};'
        'result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) run_strelka failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'

rule normalize_strelka:
    input:
        VCF=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels.vcf.gz'
    output:
        VCF=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels_vt_sorted.vcf.gz',
        Index=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels_vt_sorted.vcf.gz.tbi'    
    log:
        stdout=logdir + '/Snakefile/normalize_strelka_{sample}.stdout',
        stderr=logdir + '/Snakefile/normalize_strelka_{sample}.stderr'  
    params:
        vtOut=temp(outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels_vt.vcf'),
        ref=refGenome, 
        sortOut=temp(outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels_vt_sorted.vcf')            
    shell:
        '. /etc/profile.d/modules.sh; module load vt tabix vcftools;' 
        'vt normalize -r {params.ref} -o {params.vtOut} {input.VCF} -n >> {log.stdout} 2>>{log.stderr};'              
        '''awk -F"\t" '$1~/^#/ || $1!~/^GL/ && $1!~/^hs/ && $1!~/^NC/ && $1!~/^MT/ {{print}}' {params.vtOut} | vcf-sort -c > {params.sortOut} 2>>{log.stderr}; ''' 
        'bgzip {params.sortOut} && tabix -p vcf {output.VCF} 2>>{log.stderr}'
