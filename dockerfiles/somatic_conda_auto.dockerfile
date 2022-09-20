FROM condaforge/mambaforge:latest
LABEL io.github.snakemake.containerized="true"
LABEL io.github.snakemake.conda_env_hash="2dc314a67a0152c629272af73ec5140687b1a40e174ed23988c4f448047390aa"

# Step 1: Retrieve conda environments

# Conda environment:
#   source: ../somatic-conda/workflow/envs/gatk3_others.yaml
#   prefix: /conda-envs/4a79c558437cee539af483ce6f91b6ba
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     - gatk=3.8=hdfd78af_11
#     - vcftools=0.1.16
#     - picard=2.26.9
RUN mkdir -p /conda-envs/4a79c558437cee539af483ce6f91b6ba
COPY ../somatic-conda/workflow/envs/gatk3_others.yaml /conda-envs/4a79c558437cee539af483ce6f91b6ba/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/gatk4.yaml
#   prefix: /conda-envs/7a20045af56a1dc86151425a96413914
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     # - gatk4=4.0.11.0
#     - gatk4=4.1.3.0
RUN mkdir -p /conda-envs/7a20045af56a1dc86151425a96413914
COPY ../somatic-conda/workflow/envs/gatk4.yaml /conda-envs/7a20045af56a1dc86151425a96413914/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/java18.yaml
#   prefix: /conda-envs/d0ab2c4d903b1c55411d5961debd64ca
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     - java-jdk=8.0.112
RUN mkdir -p /conda-envs/d0ab2c4d903b1c55411d5961debd64ca
COPY ../somatic-conda/workflow/envs/java18.yaml /conda-envs/d0ab2c4d903b1c55411d5961debd64ca/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/lofreq.yaml
#   prefix: /conda-envs/276370b438dfa7a151b5018ca4e2091d
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#   #  - lofreq=2.1.3.1
#     - samtools=1.12
#     - lofreq=2.1.5
#   #  - openssl=1.0
RUN mkdir -p /conda-envs/276370b438dfa7a151b5018ca4e2091d
COPY ../somatic-conda/workflow/envs/lofreq.yaml /conda-envs/276370b438dfa7a151b5018ca4e2091d/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/manta.yaml
#   prefix: /conda-envs/611d92b5edb7341bf7309b08f8f3b363
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     - manta=1.5.0
RUN mkdir -p /conda-envs/611d92b5edb7341bf7309b08f8f3b363
COPY ../somatic-conda/workflow/envs/manta.yaml /conda-envs/611d92b5edb7341bf7309b08f8f3b363/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/muse.yaml
#   prefix: /conda-envs/2cd31c2f277639516da1f74977e91214
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     - muse=1.0.rc
RUN mkdir -p /conda-envs/2cd31c2f277639516da1f74977e91214
COPY ../somatic-conda/workflow/envs/muse.yaml /conda-envs/2cd31c2f277639516da1f74977e91214/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/strelka.yaml
#   prefix: /conda-envs/c206f1c050e17af30d6a2bf5c8f01824
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     - strelka=2.9.10
RUN mkdir -p /conda-envs/c206f1c050e17af30d6a2bf5c8f01824
COPY ../somatic-conda/workflow/envs/strelka.yaml /conda-envs/c206f1c050e17af30d6a2bf5c8f01824/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/vardict.yaml
#   prefix: /conda-envs/66ee0c85b29966199808af102641a761
#   channels:
#     - bioconda
#     - conda-forge
#     - r
#     - defaults
#   dependencies:
#     - vardict=2019.06.04
#     - samtools=1.9
#     - tabix=1.11
#     - r=3.6.0
#     - perl=5.26.2
RUN mkdir -p /conda-envs/66ee0c85b29966199808af102641a761
COPY ../somatic-conda/workflow/envs/vardict.yaml /conda-envs/66ee0c85b29966199808af102641a761/environment.yaml

# Conda environment:
#   source: ../somatic-conda/workflow/envs/vcftools.yaml
#   prefix: /conda-envs/b2f5e43cc118be3a43499b0fab902443
#   channels:
#     - bioconda
#     - conda-forge
#     - defaults
#   dependencies:
#     - vcftools=0.1.16
#     - perl-vcftools-vcf=0.1.16
#     - tabix=1.11
#   #  - vt=0.57721
#     - vt=2015.11.10
RUN mkdir -p /conda-envs/b2f5e43cc118be3a43499b0fab902443
COPY ../somatic-conda/workflow/envs/vcftools.yaml /conda-envs/b2f5e43cc118be3a43499b0fab902443/environment.yaml

# Step 2: Generate conda environments

RUN mamba env create --prefix /conda-envs/4a79c558437cee539af483ce6f91b6ba --file /conda-envs/4a79c558437cee539af483ce6f91b6ba/environment.yaml && \
    mamba env create --prefix /conda-envs/7a20045af56a1dc86151425a96413914 --file /conda-envs/7a20045af56a1dc86151425a96413914/environment.yaml && \
    mamba env create --prefix /conda-envs/d0ab2c4d903b1c55411d5961debd64ca --file /conda-envs/d0ab2c4d903b1c55411d5961debd64ca/environment.yaml && \
    mamba env create --prefix /conda-envs/276370b438dfa7a151b5018ca4e2091d --file /conda-envs/276370b438dfa7a151b5018ca4e2091d/environment.yaml && \
    mamba env create --prefix /conda-envs/611d92b5edb7341bf7309b08f8f3b363 --file /conda-envs/611d92b5edb7341bf7309b08f8f3b363/environment.yaml && \
    mamba env create --prefix /conda-envs/2cd31c2f277639516da1f74977e91214 --file /conda-envs/2cd31c2f277639516da1f74977e91214/environment.yaml && \
    mamba env create --prefix /conda-envs/c206f1c050e17af30d6a2bf5c8f01824 --file /conda-envs/c206f1c050e17af30d6a2bf5c8f01824/environment.yaml && \
    mamba env create --prefix /conda-envs/66ee0c85b29966199808af102641a761 --file /conda-envs/66ee0c85b29966199808af102641a761/environment.yaml && \
    mamba env create --prefix /conda-envs/b2f5e43cc118be3a43499b0fab902443 --file /conda-envs/b2f5e43cc118be3a43499b0fab902443/environment.yaml && \
    mamba clean --all -y
