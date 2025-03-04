// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process PYDAMAGE_FILTER {
    tag "$meta.id"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::pydamage=0.62" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/pydamage:0.62--pyhdfd78af_0"
    } else {
        container "quay.io/biocontainers/pydamage:0.62--pyhdfd78af_0"
    }

    input:
    tuple val(meta), path(csv)

    output:
    tuple val(meta), path("pydamage_results/pydamage_filtered_results.csv"), emit: csv
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """

    pydamage \\
        filter \\
        $options.args \\
        $csv

    echo \$(pydamage --version 2>&1)  | sed -e 's/pydamage, version //g' > ${software}.version.txt
    """
}
