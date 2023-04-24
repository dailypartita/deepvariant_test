ulimit -u 10000 # https://stackoverflow.com/questions/52026652/openblas-blas-thread-init-pthread-create-resource-temporarily-unavailable/54746150#54746150
BIN_VERSION="1.5.0"
mkdir -p deepvariant_output

docker run -v ~/work/PacBio/deepvariant/reference:/reference -v ~/work/PacBio/deepvariant/input:/input -v ~/work/PacBio/deepvariant/deepvariant_output:/deepvariant_output \
  google/deepvariant: /opt/deepvariant/bin/run_deepvariant \
    --model_type PACBIO \
    --ref /reference/GRCh38_no_alt_analysis_set.fasta \
    --reads /input/HG003.GRCh38.chr20.pFDA_truthv2.bam \
    --output_vcf /deepvariant_output/output.vcf.gz \
    --num_shards $(nproc) \
    --regions chr20