version 1.0

task deepvariant_make_examples {
	input {
		String sample_id
		Array[File] aligned_bams
		Array[File] aligned_bam_indices

		File reference
		File reference_index

		Int deepvariant_threads
		String deepvariant_version

	}

	Int disk_size = ceil(size(aligned_bams[0], "GB") * length(aligned_bams) * 2 + 50)
	Int mem_gb = deepvariant_threads * 4

	command <<<
		set -euo pipefail

		seq 0 ~{deepvariant_threads - 1} \
		| parallel \
			--jobs ~{deepvariant_threads} \
			--halt 2 \
			/opt/deepvariant/bin/make_examples \
				--norealign_reads \
				--vsc_min_fraction_indels 0.12 \
				--pileup_image_width 199 \
				--track_ref_reads \
				--phase_reads \
				--partition_size=25000 \
				--max_reads_per_partition=600 \
				--alt_aligned_pileup=diff_channels \
				--add_hp_channel \
				--sort_by_haplotypes \
				--parse_sam_aux_fields \
				--min_mapping_quality=1 \
				--mode calling \
				--ref ~{reference} \
				--reads ~{sep="," aligned_bams} \
				--examples ~{sample_id}.examples.tfrecord@~{deepvariant_threads}.gz \
				--gvcf ~{sample_id}.gvcf.tfrecord@~{deepvariant_threads}.gz \
				--task {}
	>>>

	output {
		Array[File] example_tfrecords = glob("~{sample_id}.examples.tfrecord*.gz")
		Array[File] nonvariant_site_tfrecords = glob("~{sample_id}.gvcf.tfrecord*.gz")
	}

	runtime {
		docker: "google/deepvariant:~{deepvariant_version}"
		cpu: deepvariant_threads
		memory: mem_gb + " GB"
		disk: disk_size + " GB"
	}
}

task deepvariant_call_variants {
	input {
		String sample_id
		String reference_name
		Array[File] example_tfrecords

		# DeepVariantModel? deepvariant_model
		Int deepvariant_threads
		String deepvariant_version

	}

	Int mem_gb = deepvariant_threads * 4
	Int disk_size = ceil(size(example_tfrecords[0], "GB") * length(example_tfrecords) * 2 + 100)

	command <<<
		set -euo pipefail

		deepvariant_model_path="/opt/models/pacbio/model.ckpt"

		# extract the path where the first example_tfrecord is located; all example_tfrecords will be located at the same base path
		example_tfrecord_dir=$(dirname ~{example_tfrecords[0]})

		/opt/deepvariant/bin/call_variants \
			--outfile ~{sample_id}.~{reference_name}.call_variants_output.tfrecord.gz \
			--examples "$example_tfrecord_dir/~{sample_id}.examples.tfrecord@~{deepvariant_threads}.gz" \
			--checkpoint "${deepvariant_model_path}"
	>>>

	output {
		File tfrecord = "~{sample_id}.~{reference_name}.call_variants_output.tfrecord.gz"
	}

	runtime {
		docker: "google/deepvariant:~{deepvariant_version}"
		cpu: deepvariant_threads
		memory: mem_gb + " GB"
		disk: disk_size + " GB"
		disks: "local-disk " + disk_size + " HDD"
	}
}

task deepvariant_postprocess_variants {
	input {
		String sample_id
		File tfrecord
		Array[File] nonvariant_site_tfrecords

		File reference
		File reference_index
		String reference_name

		Int deepvariant_threads
		String deepvariant_version

	}

	Int disk_size = ceil((size(tfrecord, "GB") + size(reference, "GB") + size(nonvariant_site_tfrecords[0], "GB") * length(nonvariant_site_tfrecords)) * 2 + 20)

	command <<<
		set -euo pipefail

		# extract the path where the first nonvariant_site_tfrecord is located; all nonvariant_site_tfrecord will be located at the same base path
		nonvariant_site_tfrecord_dir=$(dirname ~{nonvariant_site_tfrecords[0]})

		/opt/deepvariant/bin/postprocess_variants \
			--ref ~{reference} \
			--infile ~{tfrecord} \
			--outfile ~{sample_id}.~{reference_name}.deepvariant.vcf.gz \
			--nonvariant_site_tfrecord_path "$nonvariant_site_tfrecord_dir/~{sample_id}.gvcf.tfrecord@~{deepvariant_threads}.gz" \
			--gvcf_outfile ~{sample_id}.~{reference_name}.deepvariant.g.vcf.gz
	>>>

	output {
		File vcf = "~{sample_id}.~{reference_name}.deepvariant.vcf.gz"
		File vcf_index = "~{sample_id}.~{reference_name}.deepvariant.vcf.gz.tbi"
		File gvcf = "~{sample_id}.~{reference_name}.deepvariant.g.vcf.gz"
		File gvcf_index = "~{sample_id}.~{reference_name}.deepvariant.g.vcf.gz.tbi"
		File report = "~{sample_id}.~{reference_name}.deepvariant.visual_report.html"
	}

	runtime {
		docker: "google/deepvariant:~{deepvariant_version}"
		cpu: 2
		memory: "32 GB"
		disk: disk_size + " GB"
		disks: "local-disk " + disk_size + " HDD"
	}
}