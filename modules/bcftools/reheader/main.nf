// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process BCFTOOLS_REHEADER {
    tag "$meta.id"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::bcftools=1.13" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bcftools:1.13--h3a49de5_0"
    } else {
        container "quay.io/biocontainers/bcftools:1.13--h3a49de5_0"
    }

    input:
    tuple val(meta), path(vcf)
    path fai
    path header

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    path "*.version.txt"             , emit: version

    script:
    def software         = getSoftwareName(task.process)
    def prefix           = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def update_sequences = fai ? "-f $fai" : ""
    def new_header       = header ? "-h $header" : ""
    """
    bcftools \\
        reheader \\
        $update_sequences \\
        $new_header \\
        $options.args \\
        --threads $task.cpus \\
        -o ${prefix}.vcf.gz \\
        $vcf

    echo \$(bcftools --version 2>&1) | sed 's/^.*bcftools //; s/ .*\$//' > ${software}.version.txt
    """
}
