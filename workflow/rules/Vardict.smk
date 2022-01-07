### VarDict: /DCEG/CGF/Bioinformatics/software/VarDict
# /DCEG/CGF/Bioinformatics/software/VarDictJava/build/distributions/VarDict-1.6.0/bin/VarDict
# {params.exe}/testsomatic.R

### GATK: /DCEG/Projects/Exome/SequencingData/GATK_binaries/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar

if config['VardictSplit']:
    rule split_bed_file:
        input: 
            bed = bedFile
        output:
            bed = outputDir + '/' + VardictDir + '/split_regions/{chrom}.bed'
        log:
            stdout=logdir + '/Snakefile/split_bed_file_{chrom}.stdout',
            stderr=logdir + '/Snakefile/split_bed_file_{chrom}.stderr'
        shell:
            'grep "^{wildcards.chrom}[[:space:]]" {input.bed} > {output.bed} || true > {output} 2>{log.stderr}'     
    
    ### R --version R version 3.4.3
    rule call_Vardict:
        input:
            bed=outputDir + '/' + VardictDir + '/split_regions/{chrom}.bed',
            tumorBam=get_tumor,
            normalBam=get_normal
        output: 
            gz = outputDir + '/' + VardictDir + '/split_regions/{sample}_{chrom}.vcf.gz',
            index = outputDir + '/' + VardictDir + '/split_regions/{sample}_{chrom}.vcf.gz.tbi'
        params:
            minaf=MinAF,
            ref=refGenome,
            tumorname=lambda wildcards: tumorNameDict[wildcards.sample],
            normalname=lambda wildcards: normalNameDict[wildcards.sample]            
        threads:
            8 
        log:
            stdout=logdir + '/Snakefile/call_Vardict_{sample}_{chrom}.stdout',
            stderr=logdir + '/Snakefile/call_Vardict_{sample}_{chrom}.stderr'    
        conda:
            "../envs/vardict.yaml"        
        shell:
            #'. /etc/profile.d/modules.sh; module load samtools R jdk/1.8.0_111 tabix;'
            """
            vardict -G {params.ref} -f {params.minaf} -N {params.tumorname} -b "{input.tumorBam}|{input.normalBam}" -c 1 -S 2 -E 3 -g 4 -Q 10 {input.bed} | testsomatic.R |  var2vcf_paired.pl -P 0.9 -m 4.25 -f 0.1 -M  -N "{params.tumorname}|{params.normalname}" -f {params.minaf} | bgzip > {output.gz} 2>{log.stderr}
            result=$?; if [[ $result -ne 0 ]]; then echo "Error: $(date) call_Vardict failed!" ; exit;fi >> {log.stdout} 2>>{log.stderr}
            tabix -p vcf {output.gz} >> {log.stdout} 2>>{log.stderr}
            """

    rule merge_Vardict:
        input:
            expand(outputDir + '/' + VardictDir + '/split_regions/{{sample}}_{chrom}.vcf.gz', chrom=chromList)
        output: 
            outputDir + '/' + VardictDir + '/{sample}_all.vcf'
        conda:
            "../envs/vcftools.yaml"
        shell:
            #". /etc/profile.d/modules.sh; module load zlib vcftools;"
            "vcf-concat {input} > {output}"
                    
else:
    rule call_Vardict:
        input:
            tumorBam=get_tumor,
            normalBam=get_normal
        output: 
            outputDir + '/' + VardictDir + '/{sample}_all.vcf'
        params:
            exe=VardictExe,
            minaf=MinAF,
            ref=refGenome,
            bed=bedFile,
            tumorname=lambda wildcards: tumorNameDict[wildcards.sample],
            normalname=lambda wildcards: normalNameDict[wildcards.sample]            
        threads:
            8 
        log:
            stdout=logdir + '/Snakefile/call_Vardict_{sample}.stdout',
            stderr=logdir + '/Snakefile/call_Vardict_{sample}.stderr'
        conda:
            "../envs/vardict.yaml"            
        shell:
            """
            vardict -G {params.ref} -f {params.minaf} -N Tumor -b "{input.tumorBam}|{input.normalBam}" -c 1 -S 2 -E 3 -g 4 -Q 10 {params.bed} | testsomatic.R | var2vcf_paired.pl -P 0.9 -m 4.25 -f 0.1 -M  -N "Tumor|Normal" -f {params.minaf} > {output} 2>{log.stderr}
            result=$(tail -c 1 {output} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) call_Vardict failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr}
            """

        
rule filter_Vardict:
    input:
        outputDir + '/' + VardictDir + '/{sample}_all.vcf'
    output:
        outputDir + '/' + VardictDir + '/{sample}_final.vcf'
    params:
        #exe=gatkExe,
        ref=refGenome,
        bed=bedFile,
        intermediate=temp(outputDir + '/' + VardictDir + '/{sample}_all_sorted.vcf'),
        intermediate2=temp(outputDir + '/' + VardictDir + '/{sample}_all_fil.vcf')
    log:
        stdout=logdir + '/Snakefile/filter_Vardict_{sample}.stdout',
        stderr=logdir + '/Snakefile/filter_Vardict_{sample}.stderr'   
    conda:
        "../envs/gatk3_others.yaml"         
    shell:
        # '. /etc/profile.d/modules.sh; module load jdk/1.8.0_111 vcftools zlib ;'
        ''' awk '$1~/^#/ || ($4!=$5 && $4~/^[AGCTagct]+$/ && $5~/^[AGCTagct]+$/ && $7==\"PASS\" && $8~/STATUS=[A-Za-z]+Somatic/) {{print}}' {input} | sed 's/fileformat=VCFv4.3/fileformat=VCFv4.2/'>  {params.intermediate} 2>{log.stderr}; ''' #GATK error out with vcf format version
        'result=$(tail -c 1 {params.intermediate} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) filter_Vardict failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'
        'gatk3 -T VariantFiltration -R {params.ref} -o {params.intermediate2} --variant {params.intermediate} --filterExpression \"((AF*DP < 6) && ((MQ < 55.0 && NM > 1.0) || (MQ < 60.0 && NM > 2.0) || (DP < 10) || (QUAL < 45)))\" --filterName \"VardictFilter\"  >> {log.stdout} 2>>{log.stderr}; '
        'gatk3 -T SelectVariants --disable_auto_index_creation_and_locking_when_reading_rods -R {params.ref} -o {output} --variant {params.intermediate2} -L {params.bed} >> {log.stdout} 2>>{log.stderr};'
        'result=$(tail -c 1 {output} | wc -l ); if [[ $result -ne 1 ]]; then echo "Error: $(date) filter_Vardict failed\!" ; exit;fi >> {log.stdout} 2>>{log.stderr};'

rule normalize_Vardict:
    input:
        VCF=outputDir + '/' + VardictDir + '/{sample}_final.vcf'
    output:
        VCF=outputDir + '/' + VardictDir + '/{sample}_final_vt_sorted.vcf.gz',
        Index=outputDir + '/' + VardictDir + '/{sample}_final_vt_sorted.vcf.gz.tbi'    
    log:
        stdout=logdir + '/Snakefile/normalize_Vardict_{sample}.stdout',
        stderr=logdir + '/Snakefile/normalize_Vardict_{sample}.stderr'  
    params:
        vtOut=temp(outputDir + '/' + VardictDir + '/{sample}_final_vt.vcf'),
        ref=refGenome, 
        sortOut=temp(outputDir + '/' + VardictDir + '/{sample}_final_vt_sorted.vcf')   
    conda:
        "../envs/vcftools.yaml"         
    shell:
        #'. /etc/profile.d/modules.sh; module load vt tabix vcftools;' 
        'vt normalize -r {params.ref} -o {params.vtOut} {input.VCF} -n >> {log.stdout} 2>>{log.stderr};'              
        '''awk -F"\t" '$1~/^#/ || $1!~/^GL/ && $1!~/^hs/ && $1!~/^NC/ && $1!~/^MT/ {{print}}' {params.vtOut} | vcf-sort -c > {params.sortOut} 2>>{log.stderr}; ''' 
        'bgzip {params.sortOut} && tabix -p vcf {output.VCF} 2>>{log.stderr}'
        