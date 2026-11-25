#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

params.reads  = "${HOME}/nf-data/sarek3-test/test_{1,2}.fastq.gz"
params.ref    = "${HOME}/nf-data/sarek3-test/genome.fasta"
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
    fastp -i ${r1} -I ${r2} \
        -o ${sample}_R1.trimmed.fastq.gz -O ${sample}_R2.trimmed.fastq.gz \
        -h ${sample}.fastp.html -j ${sample}.fastp.json \
        --thread ${task.cpus}
    """
}

process BWAMEM2_INDEX {
    container 'community.wave.seqera.io/library/bwa-mem2_htslib_samtools:db98f81f55b64113'

    input:
    path fasta

    output:
    path "index"

    script:
    """
    mkdir index
    bwa-mem2 index -p index/genome ${fasta}
    """
}

process BWAMEM2_MEM {
    tag "$sample"
    publishDir "${params.outdir}/align", mode: 'copy'
    container 'community.wave.seqera.io/library/bwa-mem2_htslib_samtools:db98f81f55b64113'

    input:
    tuple val(sample), path(r1), path(r2)
    path index

    output:
    tuple val(sample), path("${sample}.sorted.bam"), path("${sample}.sorted.bam.bai")

    script:
    """
    bwa-mem2 mem -t ${task.cpus} \
        -R "@RG\\tID:${sample}\\tSM:${sample}\\tPL:ILLUMINA\\tLB:${sample}" \
        ${index}/genome ${r1} ${r2} \
        | samtools sort -@ ${task.cpus} -o ${sample}.sorted.bam -
    samtools index ${sample}.sorted.bam
    """
}

process GATK_MARKDUP {
    tag "$sample"
    publishDir "${params.outdir}/markdup", mode: 'copy'
    container 'community.wave.seqera.io/library/gatk4-lite_samtools:9b6806e26dd32afe'

    input:
    tuple val(sample), path(bam), path(bai)

    output:
    tuple val(sample), path("${sample}.markdup.bam"), path("${sample}.markdup.bam.bai")
    path "${sample}.markdup_metrics.txt"

    script:
    """
    gatk --java-options "-Xmx2g" MarkDuplicates \
        -I ${bam} -O ${sample}.markdup.bam -M ${sample}.markdup_metrics.txt
    samtools index ${sample}.markdup.bam
    """
}

process SAMTOOLS_FAIDX {
    publishDir "${params.outdir}/reference", mode: 'copy'
    container 'community.wave.seqera.io/library/htslib_samtools:1.25--704fb80d75745bd4'

    input:
    path fasta

    output:
    path "${fasta}.fai"

    script:
    """
    samtools faidx ${fasta}
    """
}

process GATK_DICT {
    publishDir "${params.outdir}/reference", mode: 'copy'
    container 'community.wave.seqera.io/library/gatk4-lite:4.7.0.0--79918b8b2632f4b1'

    input:
    path fasta

    output:
    path "${fasta.baseName}.dict"

    script:
    """
    gatk CreateSequenceDictionary -R ${fasta} -O ${fasta.baseName}.dict
    """
}

workflow {
    Channel.fromFilePairs(params.reads, checkIfExists: true)
        .map { sample, files -> tuple(sample, files[0], files[1]) }
        .set { reads_ch }

    FASTP(reads_ch)
    BWAMEM2_INDEX(file(params.ref))
    BWAMEM2_MEM(FASTP.out[0], BWAMEM2_INDEX.out)
    GATK_MARKDUP(BWAMEM2_MEM.out[0])
    SAMTOOLS_FAIDX(file(params.ref))
    GATK_DICT(file(params.ref))
}
