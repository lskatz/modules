// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

def VERSION = '1.4.4a'

process VARIANTBAM {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::variantbam=1.4.4a" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/variantbam:1.4.4a--h7d7f7ad_5"
    } else {
        container "quay.io/biocontainers/variantbam:1.4.4a--h7d7f7ad_5"
    }

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam")         , emit: bam
    path "*.version.txt"                   , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    variant \\
        $bam \\
        -o ${prefix}.bam \\
        $options.args

    echo $VERSION > ${software}.version.txt
    """
}
