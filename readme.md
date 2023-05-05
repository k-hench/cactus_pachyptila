## Background

This is a [snakemake](https://snakemake.github.io/) adapataion (Mölder *et al.* 2021) of a [stepwise execution](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/progressive.md#running-step-by-step) of a [progressive cactus alignment](https://github.com/ComparativeGenomicsToolkit/cactus) (Armstrong *et al.* 2020) to create a hierarchical alignment of multiple genome sequences (a `.hal` file, Hickey, G. *et al.* 2013).

The workflow is based on the official cactus documentation and the tuorial [Cactus on the FASRC Cluster](https://informatics.fas.harvard.edu/cactus-on-the-fasrc-cluster.html) by the Harvard Faculty of Arts and Sciences.

## Running the pipeline

The pipeline execution is a two-step process, as the number of 'rounds' of the cactus alignment can not be determined before the compilation of the cactus instructions.

Therefore, to run the pipeline, first call `snakemake <options> cactus_prep` to create the file "results/cactus/job_inventory.tsv" that lists the number of jobs within each cactus round and which is  needed for the rules within `cactus_stepwise.smk`.

Then, run `snakemake <options> cactus_stepwise` for the actual alignment.

## References

[Armstrong, J. *et al.* (2020)](https://doi.org/10.1038/s41586-020-2871-y) *Progressive Cactus is a multiple-genome aligner for the thousand-genome era.* Nature, 587(7833), 246–251. 

[Hickey, G. *et al.* (2013)](https://doi.org/10.1093/bioinformatics/btt128) *HAL: a hierarchical format for storing and analyzing multiple genome alignments.* Bioinformatics, 29(10), 1341–1342. 

[Mölder, F. *et al.* (2021)](https://doi.org/10.12688/f1000research.29032.1) *Sustainable data analysis with Snakemake* (10:33). F1000Research. 
