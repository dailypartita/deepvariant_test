mkdir -p happy

docker run \
	-v ~/work/PacBio/deepvariant/reference:/reference \
	-v ~/work/PacBio/deepvariant/input:/input \
	-v ~/work/PacBio/deepvariant/deepvariant_output:/deepvariant_output \
	-v ~/work/PacBio/deepvariant/benchmark:/benchmark \
	-v ~/work/PacBio/deepvariant/happy:/happy \
  jmcdani20/hap.py:v0.3.12 /opt/hap.py/bin/hap.py \
        --threads $(nproc) \
        -r reference/GRCh38_no_alt_analysis_set.fasta \
        -f benchmark/HG003_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
        -o happy/giab-comparison.v4.2.first_pass \
        --engine=vcfeval \
        --pass-only \
        -l chr20 \
        benchmark/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
        deepvariant_output/output.vcf.gz