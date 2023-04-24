version 1.0

# Call variants using DeepVariant

import "./structer.wdl"
import "../tasks/deepvariant_task.wdl" as deepvariant_task

workflow deepvariant {

	meta {
		description: "https://github.com/PacificBiosciences/wdl-common/blob/main/wdl/workflows/deepvariant"
	}

	input {
		String sample_id
		Array[IndexData] aligned_bams

		IndexData reference_fasta
		String reference_name

		String deepvariant_version
		# String DeepVariantModel? deepvariant_model

		# RuntimeAttributes default_runtime_attributes
	}

	Int deepvariant_threads = 48

	scatter (bam_object in aligned_bams) {
		File aligned_bam = bam_object.data
		File aligned_bam_index = bam_object.data_index
	}

	call deepvariant_task.deepvariant_make_examples as deepvariant_make_examples {
		input:
			sample_id = sample_id,
			aligned_bams = aligned_bam,
			aligned_bam_indices = aligned_bam_index,
			reference = reference_fasta.data,
			reference_index = reference_fasta.data_index,
			deepvariant_threads = deepvariant_threads,
			deepvariant_version = deepvariant_version,
			# runtime_attributes = default_runtime_attributes
	}

	call deepvariant_task.deepvariant_call_variants as deepvariant_call_variants{
		input:
			sample_id = sample_id,
			reference_name = reference_name,
			example_tfrecords = deepvariant_make_examples.example_tfrecords,
			# deepvariant_model = deepvariant_model,
			deepvariant_threads = deepvariant_threads,
			deepvariant_version = deepvariant_version,
			# runtime_attributes = default_runtime_attributes
	}

	call deepvariant_task.deepvariant_postprocess_variants as deepvariant_postprocess_variants {
		input:
			sample_id = sample_id,
			tfrecord = deepvariant_call_variants.tfrecord,
			nonvariant_site_tfrecords = deepvariant_make_examples.nonvariant_site_tfrecords,
			reference = reference_fasta.data,
			reference_index = reference_fasta.data_index,
			reference_name = reference_name,
			deepvariant_threads = deepvariant_threads,
			deepvariant_version = deepvariant_version,
			# runtime_attributes = default_runtime_attributes
	}

	output {
		IndexData vcf = {"data": deepvariant_postprocess_variants.vcf, "data_index": deepvariant_postprocess_variants.vcf_index}
		IndexData gvcf = {"data": deepvariant_postprocess_variants.gvcf, "data_index": deepvariant_postprocess_variants.gvcf_index}
		File report = deepvariant_postprocess_variants.report
	}

	parameter_meta {
		sample_id: {help: "Sample ID; used for naming files"}
		aligned_bams: {help: "Bam and index aligned to the reference genome for each movie associated with all samples in the cohort"}
		reference: {help: "Reference genome data"}
		deepvariant_version: {help: "Version of deepvariant to use"}
		# deepvariant_model: {help: "Optional deepvariant model file to use"}
		# default_runtime_attributes: {help: "Default RuntimeAttributes; spot if preemptible was set to true, otherwise on_demand"}
	}
}