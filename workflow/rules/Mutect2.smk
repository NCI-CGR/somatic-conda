# vt --version
# vt v0.5772-60f436c3
# https://bioconda.github.io/recipes/vt/README.html#package-vt

# Loading channels: done
# # Name                       Version           Build  Channel             
# vt                           0.57721      h41af197_4  bioconda            
# vt                           0.57721      hdf88d34_2  bioconda            
# vt                           0.57721      heae7c10_3  bioconda            
# vt                           0.57721      hf74b74d_0  bioconda            
# vt                           0.57721      hf74b74d_1  bioconda            
# vt                        2015.11.10               0  bioconda            
# vt                        2015.11.10               1  bioconda            
# vt                        2015.11.10               2  bioconda            
# vt                        2015.11.10      h5ef6573_4  bioconda            
# vt                        2015.11.10      he941832_3  bioconda  

if config['PonPrepare']: 
    PON = outputDir + '/' + Mutect2Dir + '/PON/pon.vcf.gz'
else:
    PON = config['PON']
    
rule run_mutect2:
    input:
        tumorBam=get_tumor,
        normalBam=get_normal,
        pp=PON
    output:
        outputDir + '/' + Mutect2Dir + '/{sample}_WES_passed.vcf'
    params:
        ref=refGenome,
        bed=bedFile,
        # tumorName=lambda wildcards: [tumorNameDict[wildcards.sample]],
        # normalName=lambda wildcards: [normalNameDict[wildcards.sample]],
        pon='--panel-of-normals ' + PON if (config['PON'] != 'NA' or config['PonPrepare']) else [],
        raw=outputDir + '/' + Mutect2Dir + '/{sample}_WES.vcf'
    threads:
        4
    log:
        stdout=logdir + '/Snakefile/run_mutect2_{sample}.stdout',
        stderr=logdir + '/Snakefile/run_mutect2_{sample}.stderr' 
    conda:
        "../envs/gatk4.yaml"         
    shell:
        #'. /etc/profile.d/modules.sh; module load jdk/1.8.0_111 samtools;' 
        'NORMAL=$(gatk GetSampleName -I {input.normalBam} -O /dev/stdout 2>/dev/null); TUMOR=$(gatk GetSampleName -I {input.tumorBam} -O /dev/stdout 2>/dev/null); echo "===$NORMAL==="; gatk Mutect2 --disable-sequence-dictionary-validation true --reference {params.ref} -L {params.bed} -I {input.normalBam} -I {input.tumorBam}  -normal $NORMAL -tumor $TUMOR -O {params.raw} {params.pon} > {log.stdout} 2>{log.stderr};'
        #'{params.exe} Mutect2 --disable-sequence-dictionary-validation true --reference {params.ref} -L {params.bed} -I {input.normalBam} -I {input.tumorBam} -tumor Tumor -normal Normal  -O {params.raw} {params.pon} > {log.stdout} 2>{log.stderr};'
        'result=$(tail -c 1 {params.raw} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) run_mutect2 failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'
        'gatk FilterMutectCalls -R {params.ref} -V {params.raw} -O {output} > {log.stdout} 2>>{log.stderr};'
        'result=$(tail -c 1 {output} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) filter_mutect2 failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'

rule normalize_mutect2:
    input:
        VCF=outputDir + '/' + Mutect2Dir + '/{sample}_WES_passed.vcf'
    output:
        VCF=outputDir + '/' + Mutect2Dir + '/{sample}_WES_passed_vt_sorted.vcf.gz',
        Index=outputDir + '/' + Mutect2Dir + '/{sample}_WES_passed_vt_sorted.vcf.gz.tbi'    
    log:
        stdout=logdir + '/Snakefile/normalize_mutect2_{sample}.stdout',
        stderr=logdir + '/Snakefile/normalize_mutect2_{sample}.stderr'  
    params:
        vtOut=temp(outputDir + '/' + Mutect2Dir + '/{sample}_WES_passed_vt.vcf'),
        ref=refGenome, 
        sortOut=temp(outputDir + '/' + Mutect2Dir + '/{sample}_WES_passed_vt_sorted.vcf') 
    conda:
        "../envs/vcftools.yaml"           
    shell:
        # '. /etc/profile.d/modules.sh; module load vt tabix vcftools;' 
        'vt normalize -r {params.ref} -o {params.vtOut} {input.VCF} -n >> {log.stdout} 2>>{log.stderr};'              
        '''awk -F"\t" '$1~/^#/ || $1!~/^GL/ && $1!~/^hs/ && $1!~/^NC/ && $1!~/^MT/ {{print}}' {params.vtOut} | awk -v OFS='\t' '{{if ($1~/^#CHROM/) {{for (i=1;i<=9;i++) {{printf $i"\t"}} print "NORMAL\tTUMOR";}}else print;}}'| vcf-sort -c > {params.sortOut} 2>>{log.stderr}; ''' 
        'bgzip {params.sortOut} && tabix -p vcf {output.VCF} 2>>{log.stderr}'
        