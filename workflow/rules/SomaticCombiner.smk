rule ensemble_5caller:
    input:
        L=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels.vcf.gz', #vt normalized vcf file will have vcf header of contigs without length causing errors during vcf merge step.
        l=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.snvs.vcf.gz', 
        S=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.indels_vt_sorted.vcf.gz',
        s=outputDir + '/' + StrelkaDir + '/{sample}/results/variants/somatic.snvs.vcf.gz',   
        M=outputDir + '/' + Mutect2Dir + '/{sample}_WES_passed_vt_sorted.vcf.gz',   
        u=outputDir + '/' + MuseDir + '/{sample}_passed.vcf', 
        D=outputDir + '/' + VardictDir + '/{sample}_final_vt_sorted.vcf.gz'
    output: 
        temp(outputDir + '/Ensemble/{sample}_5callers_voting.vcf')
    threads:
        4           
    params:
        exe=config['SomaticCombiner'],
        #gatkexe=gatkExe,
        tumorName=lambda wildcards: [tumorNameDict[wildcards.sample]],
        normalName=lambda wildcards: [normalNameDict[wildcards.sample]],            
        ref=refGenome 
    log:
        stdout=logdir + '/Snakefile/ensemble_5caller_{sample}.stdout',
        stderr=logdir + '/Snakefile/ensemble_5caller_{sample}.stderr'  
    conda:
        "../envs/java18.yaml"          
    shell:
        #'. /etc/profile.d/modules.sh; module load jdk/1.8.0_111 ;'        
        'java  -jar {params.exe} -l {input.l} -s {input.s} -S {input.S} -L {input.L} -M {input.M} -u {input.u} -D {input.D} -o {output} > {log.stdout} 2>{log.stderr};'   
        'sed -i "s/TUMOR\tNORMAL/{params.tumorName}\t{params.normalName}/" {output} >>{log.stdout} 2>>{log.stderr} ; '            
        #'if [[ $? -ne 0 ]]; then echo "Error: $(date) ensemble output validation is failed!"; exit;fi >> {log.stdout} 2>>{log.stderr};'

### /DCEG/Resources/Tools/Picard/picard-2.21.1/picard        
rule filter_ensemble:
    input:
        outputDir + '/Ensemble/{sample}_5callers_voting.vcf'
    output:
        outputDir + '/Ensemble/{sample}_5callers_voting_PASS.vcf'
    log:
        stdout=logdir + '/Snakefile/filter_ensemble_{sample}.stdout',
        stderr=logdir + '/Snakefile/filter_ensemble_{sample}.stderr' 
    params:
        #gatkexe=gatkExe,
        ref=refGenome,
        refDict=config['refGenomeDict'],
        prefix=outputDir + '/Ensemble/{sample}_5callers_voting',
        sortVcf=outputDir + '/Ensemble/{sample}_5callers_voting.sort.vcf',
        recodeVcf=temp(outputDir + '/Ensemble/{sample}_5callers_voting.recode.vcf')   
    conda:
        "../envs/gatk3_others.yaml"         
    shell:
        #'. /etc/profile.d/modules.sh; module load jdk/1.8.0_111 picard zlib vcftools;'
        'vcftools --vcf {input} --recode  --recode-INFO-all --out {params.prefix};'
        'picard SortVcf I={params.recodeVcf} O={params.sortVcf} SD={params.refDict};'
        'gatk3 -T ValidateVariants -R {params.ref} -V {params.sortVcf} > {log.stdout} 2>{log.stderr}; '           
        '''awk -F"\t" '{{if ( $1 ~ "^#" || $7 ~ ";PASS" ){{print}}}}' {params.sortVcf} > {output};'''
            
        
rule merge_ensemble:
    input:
        expand(outputDir + '/Ensemble/{sample}_5callers_voting_PASS.vcf', sample=SAMPLES) if config['mergeTag'] == 'PASS' else expand(outputDir + '/Ensemble/{sample}_5callers_voting.vcf', sample=SAMPLES)
    output:
        outputDir + '/Ensemble/merge/merged.vcf'  
    params:
        #gatkexe=gatkExe,
        ref=refGenome,
        vcfList = lambda wildcards, input:" -V ".join(input)            
    log:
        stdout=logdir + '/Snakefile/merge_ensemble.stdout',
        stderr=logdir + '/Snakefile/merge_ensemble.stderr'   
    conda:
        "../envs/gatk3_others.yaml"         
    shell:      
        # '. /etc/profile.d/modules.sh; module load jdk/1.8.0_111 ;'
        'gatk3 -R {params.ref} -T CombineVariants -V {params.vcfList} -o {output} -genotypeMergeOptions UNIQUIFY > {log.stdout} 2>{log.stderr}'
            
