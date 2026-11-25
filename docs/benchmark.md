# Benchmark: SNV and indel accuracy on GIAB HG002 (chr21 slice)

## Test setup

| Item | Value |
|---|---|
| Sample | HG002 (GIAB Ashkenazi son), Illumina 2x250 PCR-free, NIST |
| Reads | GRCh38 BAM, chr21:20,000,000-25,000,000, converted back to FASTQ (725,914 read pairs) |
| Reference | chr21 FASTA (nf-core test data, hg38) |
| Truth set | GIAB HG002 v4.2.1, GRCh38 small variants |
| Confident regions | `HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed` |
| Comparison window | chr21:20,000,000-25,000,000 |
| Caller | GATK 4.7.0.0 HaplotypeCaller, no filtering (raw calls) |
| Scorer | hap.py 0.3.15 |

## Results

| Type | Truth variants | True positives | False negatives | Recall | Precision | F1 |
|---|---|---|---|---|---|---|
| SNP | 8,000 | 7,997 | 3 | 99.96% | 99.91% | 99.94% |
| INDEL | 1,391 | 1,370 | 21 | 98.5% | 99.4% | 98.96% |

Sanity checks:
- SNP Ti/Tv: truth 1.93, our calls 1.88 (expected near 2 for human SNPs)
- Het/hom ratio: truth 1.04, our calls 1.05

## Limits

- Results are for one 5 Mb window of chromosome 21, at about 71x mean coverage.
- Precision and recall only count calls inside GIAB confident regions. About 6% of SNP calls and 32% of indel calls fall outside them and are not scored.
- Lower coverage, other chromosomes, and exome regions have not been tested yet.
- Raw calls were used. No hard filters were applied.

## Reproduce

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$HOME:/work" quay.io/biocontainers/hap.py:0.3.15--py27hcb73b3d_0 \
  hap.py /work/nf-data/giab-truth/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
  /work/wes-pipeline/results/giab/variants/giab.vcf.gz \
  -f /work/nf-data/giab-truth/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
  -r /work/nf-data/sarek3-test/genome.fasta \
  -l chr21:20000000-25000000 \
  -o /work/wes-pipeline/results/benchmark/giab
```
