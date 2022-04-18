
### GATK4: /DCEG/CGF/Bioinformatics/software/gatk-4.1.3.0/gatk 

rule mutect2_call_normal:
    input:
        normalDir + '/{normalName}.bam'
    output:
        outputDir + '/' + Mutect2Dir + '/PON/{normalName}.vcf.gz'
    params:
        ref=refGenome
    log:
        stdout=logdir + '/Snakefile/mutect2_call_normal_{normalName}.stdout',
        stderr=logdir + '/Snakefile/mutect2_call_normal_{normalName}.stderr'
    threads:
	4
    conda:
        "../envs/gatk4.yaml"
    shell:
        #'. /etc/profile.d/modules.sh; module load jdk/1.8.0_111;' 
        'gatk Mutect2 -R {params.ref} -I {input} --max-mnp-distance 0 -O {output} > {log.stdout} 2>{log.stderr}'
        
rule mutect2_GenomicsDBImport:
    input:
        expand(outputDir + '/' + Mutect2Dir + '/PON/{normalName}.vcf.gz', normalName=normalInBams)
    output:
        # o1 = outputDir + '/' + Mutect2Dir + '/PON/pon_db/vcfheader.vcf',
        # o2 = outputDir + '/' + Mutect2Dir + '/PON/pon_db/vidmap.json',
        # o3 = outputDir + '/' + Mutect2Dir + '/PON/pon_db/callset.json',
        # o4 = outputDir + '/' + Mutect2Dir + '/PON/pon_db/__tiledb_workspace.tdb',
        db = directory(outputDir + '/' + Mutect2Dir + '/PON/pon_db')
    params:
        ref=refGenome,
        bed = config['bedFile'],
        vcfList_params = lambda wildcards, input:" -V ".join(input)
    threads:
        20
    log:
        stdout=logdir + '/Snakefile/mutect2_GenomicsDBImport.stdout',
        stderr=logdir + '/Snakefile/mutect2_GenomicsDBImport.stderr'   
    conda:
        "../envs/gatk4.yaml"         
    shell:
        # '. /etc/profile.d/modules.sh; module load jdk/1.8.0_111;' 
        'gatk GenomicsDBImport -R {params.ref} --merge-input-intervals -L {params.bed} -V {params.vcfList_params} --genomicsdb-workspace-path {output.db} > {log.stdout} 2>{log.stderr}'

rule mutect2_CreateSomaticPanelOfNormals:
    input:
        db = outputDir + '/' + Mutect2Dir + '/PON/pon_db'
    output:
        outputDir + '/' + Mutect2Dir + '/PON/pon.vcf.gz'
    params:
        ref=refGenome,
        dbSNP = config['dbSNP']
    log:
        stdout=logdir + '/Snakefile/mutect2_CreateSomaticPanelOfNormals.stdout',
        stderr=logdir + '/Snakefile/mutect2_CreateSomaticPanelOfNormals.stderr'
    conda:
        "../envs/gatk4.yaml"             
    shell:
        #'. /etc/profile.d/modules.sh; module load jdk/1.8.0_111;' 
        'gatk CreateSomaticPanelOfNormals -R {params.ref} --germline-resource {params.dbSNP} -V gendb://{input} -O {output} > {log.stdout} 2>{log.stderr}'

