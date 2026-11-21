#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

params.reads  = "${HOME}/nf-data/sarek3-test/test_{1,2}.fastq.gz"
params.outdir = "results"

process FASTP {
    tag "$sample"
    publishDir "${params.outdir}/fastp", mode: 'copy'
    container 'community.wave.seqera.io/library/fastp:1.4.0--df415eab5e33cb11'

    input:
    tuple val(sample), path(r1), path(r2)

    output:
    tuple val(sample), path("${sample}_R1.trimmed.fastq.gz"), path("${sample}_R2.trimmed.fastq.gz")
    path "${sample}.fastp.html"
    path "${sample}.fastp.json"

    script:
    """
    fastp \
        -i ${r1} -I ${r2} \
        -o ${sample}_R1.trimmed.fastq.gz -O ${sample}_R2.trimmed.fastq.gz \
        -h ${sample}.fastp.html -j ${sample}.fastp.json \
        --thread ${task.cpus}
    """
}

workflow {
    Channel.fromFilePairs(params.reads, checkIfExists: true)
        .map { sample, files -> tuple(sample, files[0], files[1]) }
        .set { reads_ch }

    FASTP(reads_ch)
}
