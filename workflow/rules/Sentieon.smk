### Sentieon: /DCEG/Resources/Tools/goldenhelix/sentieon-genomics-201808.03/bin/sentieon

# TODO not completed
rule run_Sentieon:
    input:
        tumorBam=get_tumor,
        normalBam=get_normal
    output:
        outputDir + '/' + SentieonDir + '/{sample}_WES_passed.vcf'
    params:
        ref=refGenome,
        bed=bedFile,
        dbsnp='--dbsnp' + dbSNP if config['dbSNP'] != 'NA' else [],
        cosmic='--cosmic' + COSMIC if config['COSMIC'] != 'NA' else [],
        pon='--normal_panel ' + PON if (config['PON'] != 'NA' and config['PonPrepare'] != 'TRUE') else [],
        raw=outputDir + '/' + SentieonDir + '/{sample}_WES.vcf'
    threads:
        4            
    shell:
        #'. /etc/profile.d/modules.sh; module load jdk/1.8.0_111 samtools;'
        '''BASE_TUMOR=`samtools view -H {input.normalBam} |awk '$1~/^@RG/ {{for (i=1;i<=NF;i++) {{if ($i~/SM/) {{split($i,aa,":"); print aa[2]}}}}}}'|sort|uniq`; 
        BASE_NORMAL=`samtools view -H {input.normalBam} | awk '$1~/^@RG/ {{for (i=1;i<=NF;i++) {{if ($i~/SM/) {{split($i,aa,":"); print aa[2]}}}}}}'|sort|uniq`; 
        export SENTIEON_LICENSE="/DCEG/Resources/Tools/goldenhelix/Secondary-Analysis/GoldenHelix-NIH_NCI_DCEG_cluster.lic";
        time sentieon driver -t 8 -r {params.ref} -i {input.normalBam} -i {input.normalBam} --interval {params.bed} --algo TNhaplotyper --tumor_sample $BASE_TUMOR --normal_sample $BASE_NORMAL {params.dbsnp} {params.cosmic} {params.pon} {params.raw};'''
        ''' awk "($1 ~/^#/) || ($7 ~ /PASS/) {{print}}" {params.raw} > {output} '''
        