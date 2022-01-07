### /DCEG/CGF/Bioinformatics/software/lofreq_star-2.1.3.1/bin/lofreq

rule run_lofreq:
    input:
        tumorBam=get_tumorLofReq if LofreqBamPrepare else get_tumor,
        normalBam=get_normalLofReq if LofreqBamPrepare else get_normal
    output:
        indel=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels.vcf.gz.tbi',
        indelGz=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels.vcf.gz',
        snp=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.snvs.vcf.gz.tbi',
        snpGz=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.snvs.vcf.gz'
    params:
        ref=refGenome,
        bed=bedFile,
        dbsnp=dbSNP,
        prefix=outputDir + '/' + LofreqDir + '/{sample}_'
    threads:
        8
    log:
        stdout=logdir + '/Snakefile/run_lofreq_{sample}.stdout',
        stderr=logdir + '/Snakefile/run_lofreq_{sample}.stderr'
    conda:
        "../envs/lofreq.yaml"
    # run:
    #     if config['dbSNP'] == 'NA':
    #         shell('lofreq somatic -v -n {input.normalBam} -t {input.tumorBam} -f {params.ref} -l {params.bed} --threads 8 --call-indels -o {params.prefix} > {log.stdout} 2>{log.stderr};')
    #         shell('result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) run_lofreq failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr} ')
    #     else:
    #         shell('lofreq somatic -v -n {input.normalBam} -t {input.tumorBam} -f {params.ref} -l {params.bed} --threads 8 --call-indels -o {params.prefix} -d {params.dbsnp} > {log.stdout} 2>{log.stderr};')
    #         shell('result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) run_lofreq failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr} ')
    shell:
        '''
        if [[ {params.dbsnp} == 'NA' ]]; then D=""; else D=" -d {params.dbsnp}"; fi
        cmd="lofreq somatic -v -n {input.normalBam} -t {input.tumorBam} -f {params.ref} -l {params.bed} --threads 8 --call-indels -o {params.prefix} $D > {log.stdout} 2>{log.stderr}"
        eval $cmd
        result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) run_lofreq failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr}
        '''
            
rule normalize_lofreq:
    input:
        Index=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels.vcf.gz.tbi',
        VCF=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels.vcf.gz'
    output:
        VCF=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels_vt_sorted.vcf.gz',
        Index=outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels_vt_sorted.vcf.gz.tbi'    
    log:
        stdout=logdir + '/Snakefile/normalize_lofreq_{sample}.stdout',
        stderr=logdir + '/Snakefile/normalize_lofreq_{sample}.stderr'  
    params:
        vtOut=temp(outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels_vt.vcf'),
        ref=refGenome, 
        sortOut=temp(outputDir + '/' + LofreqDir + '/{sample}_somatic_final.indels_vt_sorted.vcf')  
    conda:
        "../envs/vcftools"          
    shell:
        # '. /etc/profile.d/modules.sh; module load vt tabix vcftools;' 
        'vt normalize -r {params.ref} -o {params.vtOut} {input.VCF} -n >> {log.stdout} 2>>{log.stderr};'              
        '''awk -F"\t" '$1~/^#/ || $1!~/^GL/ && $1!~/^hs/ && $1!~/^NC/ && $1!~/^MT/ {{print}}' {params.vtOut} | vcf-sort -c > {params.sortOut} 2>>{log.stderr}; ''' 
        'bgzip {params.sortOut} && tabix -p vcf {output.VCF} 2>>{log.stderr}'