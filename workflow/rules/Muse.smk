#!/usr/bin/env python3

### Muse: /DCEG/CGF/Bioinformatics/software/MuSE/MuSE
# Program: MuSE (Tools for calling somatic point mutations)

# Version: v1.0rc
#          Build Date May 15 2017
#          Build Time 10:51:32

#Muse seems not to generate any indels?
rule call_Muse:
    input:
        tumorBam=get_tumor,
        normalBam=get_normal
    output:
        outputDir + '/' + MuseDir + '/merged_{sample}_all.txt'
    params:
        exe=MuseExe,
        ref=refGenome,
        bed=bedFile,
        raw=outputDir + '/' + MuseDir + '/{sample}.snp'
    threads:
        8
    log:
        stdout=logdir + '/Snakefile/call_Muse_{sample}.stdout',
        stderr=logdir + '/Snakefile/call_Muse_{sample}.stderr'  
    conda:
        "../envs/muse.yaml"          
    shell:    
        'MuSE call -f {params.ref} -l {params.bed} -O {params.raw} {input.tumorBam} {input.normalBam} > {log.stdout} 2>{log.stderr};'
        'mv {params.raw}.MuSE.txt {output} >> {log.stdout} 2>>{log.stderr};'
        'result=$(tail -c 1 {output} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) call_Muse failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'
    
rule sump_Muse:
    input:
        outputDir + '/' + MuseDir + '/merged_{sample}_all.txt'
    output:
        outputDir + '/' + MuseDir + '/{sample}_passed.vcf'
    params:
        exe=MuseExe,
        #dbsnp=dbSNP,
        dbsnp=dbSNP if config['dbSNP'] != 'NA' else 'NA',
        raw=outputDir + '/' + MuseDir + '/{sample}.vcf'
    threads:
        2 
    log:
        stdout=logdir + '/Snakefile/sump_Muse_{sample}.stdout',
        stderr=logdir + '/Snakefile/sump_Muse_{sample}.stderr'    
    conda:
        "../envs/muse.yaml"        
    shell:
        'MuSE sump -I {input} -E –D {params.dbsnp} -O {params.raw} > {log.stdout} 2>{log.stderr};'
        'result=$(tail -c 1 {params.raw} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) sump_Muse failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'
        ''' awk ' ($1 ~/^#/) || ($7 ~ /PASS/) {{print}}' {params.raw} > {output} 2>>{log.stderr};'''
        'result=$(tail -c 1 {output} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) sump_Muse failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'