# Whole-Exome Sequencing Pipeline

A short-read germline variant calling pipeline built with Nextflow and Docker. It takes paired-end Illumina reads and produces a VCF of variants, then checks the variants against a known truth set.

**Status: in progress.** Quality control, alignment, duplicate removal, and variant calling are working. Benchmarking is done on one test region. Annotation and exome-target mode are planned.

## Pipeline stages

| Stage | Tool | Status |
|---|---|---|
| Quality control and trimming | fastp 1.4.0 | Done |
| Alignment | BWA-MEM2 | Done |
| Duplicate removal | GATK MarkDuplicates 4.7.0.0 | Done |
| Variant calling | GATK HaplotypeCaller 4.7.0.0 | Done |
| Accuracy benchmark | hap.py 0.3.15 | Done (one region) |
| Annotation | VEP or snpEff | Planned |
| Exome target mode | Target BED file | Planned |

## Results

On a 5 Mb chromosome 21 region of GIAB HG002, the raw calls reached 99.96% SNP recall and 99.91% SNP precision. Indel recall was 98.5% and precision 99.4%. See [docs/benchmark.md](docs/benchmark.md) for the full table, the test setup, and the limits.

## Requirements

- Linux, or Windows with WSL 2
- Docker
- Nextflow 26.x
- About 3 GB of RAM per process (tested on a laptop with 8 GB)

## Running

```bash
nextflow run main.nf \
  --reads "/path/to/sample_{R1,R2}.fastq.gz" \
  --ref /path/to/genome.fasta \
  --outdir results
```

Each tool runs in its own container, so no bioinformatics software needs to be installed by hand.

## Limitations

- Only one region has been benchmarked, at high coverage.
- No filtering is applied to variant calls yet.
- Annotation and exome target handling are not implemented.
