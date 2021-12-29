#!/usr/bin/env python3

rule lofreq_prepare_tumor:
    input:
        tumorDir + '/{tumorName}.bam'
#        get_tumor #cannot use this function to get the bam file because the function uses different wildcard than this rule, will get error of "AttributeError: 'Wildcards' object has no attribute 'sample'"
    output:
        tumorBam=outputDir + '/' + LofreqDir + '/tumorBAM/{tumorName}_sorted.bam', #adding another layer of folder for bam file so that the two rules won't compete for the same output file causing following errors.
        tumorBai=outputDir + '/' + LofreqDir + '/tumorBAM/{tumorName}_sorted.bam.bai',
    params:
        ref=refGenome,
        indelTumorBam=outputDir + '/' + LofreqDir + '/tumorBAM/{tumorName}_indeled.bam'
    threads:
        8
    log:
        stdout=logdir + '/Snakefile/lofreq_prepare_tumor_{tumorName}.stdout',
        stderr=logdir + '/Snakefile/lofreq_prepare_tumor_{tumorName}.stderr'
    conda:
        "../envs/lofreq.yaml"
    shell:
        #'. /etc/profile.d/modules.sh; module load samtools ;'
        'lofreq indelqual -f {params.ref} --dindel -o {params.indelTumorBam} {input} > {log.stdout} 2>{log.stderr};'
        'samtools sort -o {output.tumorBam} {params.indelTumorBam} > {log.stdout} 2>{log.stderr};'
        'samtools index {output.tumorBam} {output.tumorBai} > {log.stdout} 2>{log.stderr};'

# AmbiguousRuleException:
# Rules lofreq_prepare_normal and lofreq_prepare_tumor are ambiguous for the file /DCEG/Projects/Exome/builds/build_UMI_NP0084_22047/Result_filter5_with_rest_snakemake/Lofreq_output/SC035821-9901-2-FAB_consensus_dedup_final_fix_sorted.bam.
# Consider starting rule output with a unique prefix or constrain your wildcards.
# Wildcards:
        # lofreq_prepare_normal: normalName=SC035821-9901-2-FAB_consensus_dedup_final_fix
        # lofreq_prepare_tumor: tumorName=SC035821-9901-2-FAB_consensus_dedup_final_fix
# Expected input files:
        # lofreq_prepare_normal: /CGF/Bioinformatics/Production/Wen/20181119_NP0084-HE26_UMI/UMI_filter5_with_rest/SC035821-9901-2-FAB_consensus_dedup_final_fix.bam
        # lofreq_prepare_tumor: /CGF/Bioinformatics/Production/Wen/20181119_NP0084-HE26_UMI/UMI_filter5_with_rest/SC035821-9901-2-FAB_consensus_dedup_final_fix.bam

rule lofreq_prepare_normal:
    input:
        normalDir + '/{normalName}.bam'
#        get_normal
    output:
        normalBam=outputDir + '/' + LofreqDir + '/normalBAM/{normalName}_sorted.bam', 
        normalBai=outputDir + '/' + LofreqDir + '/normalBAM/{normalName}_sorted.bam.bai'
    params:
        ref=refGenome,
        indelNormalBam=outputDir + '/' + LofreqDir + '/normalBAM/{normalName}_indeled.bam'
    threads:
        8
    log:
        stdout=logdir + '/Snakefile/lofreq_prepare_normal_{normalName}.stdout',
        stderr=logdir + '/Snakefile/lofreq_prepare_normal_{normalName}.stderr'
    conda:
        "../envs/lofreq.yaml"
    shell:
        # '. /etc/profile.d/modules.sh; module load samtools ;'    
        'lofreq indelqual -f {params.ref} --dindel -o {params.indelNormalBam} {input} > {log.stdout} 2>{log.stderr};'
        'samtools sort -o {output.normalBam} {params.indelNormalBam} > {log.stdout} 2>{log.stderr};'
        'samtools index {output.normalBam} {output.normalBai} > {log.stdout} 2>{log.stderr};'
