<div style='color:#cc0000'>

## Disclaimer

> !! ----------------------------------------------------------------- !! <br>
> This implementation was intended for my own needs to run `cactus` on a HPC via `slurm`.<br>
>It is NOT extensivly tested, so please use and adapt with caution.<br>
> !! ----------------------------------------------------------------- !! <br>

</div>
 
## Background

This is a [snakemake](https://snakemake.github.io/) adapataion (Mölder *et al.* 2021) of a [stepwise execution](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/progressive.md#running-step-by-step) of a [progressive cactus alignment](https://github.com/ComparativeGenomicsToolkit/cactus) (Armstrong *et al.* 2020) to create a hierarchical alignment of multiple genome sequences (a `.hal` file, Hickey, G. *et al.* 2013).

The workflow is based on the official cactus documentation and the tuorial [Cactus on the FASRC Cluster](https://informatics.fas.harvard.edu/cactus-on-the-fasrc-cluster.html) by the Harvard Faculty of Arts and Sciences.
A key adaptation here was to switch from a [*filesystem image overlay*](https://apptainer.org/docs/user/main/persistent_overlays.html#filesystem-image-overlay) to a [*directory overlay*](https://apptainer.org/docs/user/main/persistent_overlays.html#directory-overlay) to allow simultaneous access to the overlay directory by processes running in parallel (preventing a ` can't open ./jobStore.img for writing, currently in use by another process` [error](https://github.com/ComparativeGenomicsToolkit/cactus/issues/261)).

The features of the adaptation are:
 - seamless execution on HPC trough `snakemake` (eg. grid enginge / slurm scheduling) 
 - execution within the [cactus container](https://quay.io/repository/comparative-genomics-toolkit/cactus?tab=info) for through [apptainer](https://apptainer.org/)

The main idea is to pull apart the individual commands created by `cactus-prepare` and store them within individual `.sh` files.
These are ordered hierarchically by the cactus rounds, allowing snakemake to work through the individual rounds successively, while parallelizing jobs within each round:

```
sh/ 
└── cactus
    ├── round_1
    │   ├── job_1
    │   │   ├── step_1.sh
    │   │   └── step_2.sh
    │   └── job_1.sh
    ├── round_2
    │   ├── job_1
    │   │   ├── step_1.sh
    │   │   ├── step_2.sh
    │   │   └── step_3.sh
    │   ├── job_1.sh
    │   ├── job_2
    │   │   ├── step_1.sh
    │   │   ├── step_2.sh
    │   │   └── step_3.sh
    │   └── job_2.sh
    ├── round_3
    │   ├── job_1
    │   │   ├── step_1.sh
    │   │   ├── step_2.sh
    │   │   └── step_3.sh
    │   └── job_1.sh
    ├── round_4
    │   ├── job_1
    │   │   ├── step_1.sh
    │   │   ├── step_2.sh
    │   │   └── step_3.sh
    │   └── job_1.sh
    └── round_5
        ├── job_1
        │   ├── step_1.sh
        │   ├── step_2.sh
        │   └── step_3.sh
        └── job_1.sh
```

## Preparations

### Install `apptainer`

The `snakemake` pipeline uses `apptainer` to run `cactus` within the official container (<docker://quay.io/comparative-genomics-toolkit/cactus:v2.5.1>, specified within `config.yml`).

For this to work `apptainer` (or `singularity`) [needs to be installed](https://apptainer.org/docs/admin/main/installation.html) on your system.

You can check that the pices are in place by running:

```sh
apptainer shell docker://quay.io/comparative-genomics-toolkit/cactus:v2.5.1
```

If sucessfully opens a shell within the `cactus` container, you should be set (you can leave the shell by typing `exit`).

Container check (on first test, this will take a bit longer and report the download of the container):

```sh
$ apptainer shell docker://quay.io/comparative-genomics-toolkit/cactus:v2.5.1
INFO:    Using cached SIF image
Apptainer> which cactus
/home/cactus/cactus_env/bin/cactus
Apptainer> exit
$
```

### Conda environemnt for `R`

The `R` scripts that chops down the `cactus` instructions requries `R > 4.1`.
If you want to be independent of the locally installed `R` version, you can use the provided `conda` environment for the `R` processes.

To install the required `conda` environment run:

```sh
conda env create -f workflow/envs/r_base.yml
```

Then, when calling `snakemake` use the `--use-conda` flag, eg:

```sh
snakemake -c 1 --use-conda cactus_prep
```

## Running the pipeline

The pipeline execution is a two-step process, as the number of 'rounds' of the cactus alignment can not be determined before the compilation of the cactus instructions.

Therefore, to run the pipeline, first call `snakemake <options> cactus_prep` to create the file "results/cactus/job_inventory.tsv" that lists the number of jobs within each cactus round and which is  needed for the rules within `cactus_stepwise.smk`.

Then, run `snakemake <options> cactus_stepwise` for the actual alignment.

A minimal example of a complete run would be:

```sh
snakemake -c 1 --use-conda cactus_prep
snakemake -c 1 --use-singularity cactus_stepwise
```

For the example data, this should provide the final `hal` file (`results/cactus/mammal_set.hal`), as well as check of this file (`results/cactus/mammal_set_check.check`)

```sh
cat results/cactus/mammal_set_check.check 
#> hal v2.2
#> ((simHuman_chr6:0.144018,(simMouse_chr6:0.084509,simRat_chr6:0.091589)mr:0.271974)Anc1:0.020593,(simCow_chr6:0.18908,simDog_chr6:0.16303)Anc2:0.032898)Anc0;
#> 
#> GenomeName, NumChildren, Length, NumSequences, NumTopSegments, NumBottomSegments
#> Anc0, 2, 564579, 1, 0, 7936
#> Anc1, 2, 584785, 1, 9796, 41365
#> simHuman_chr6, 0, 597871, 1, 41960, 0
#> mr, 2, 610030, 1, 37996, 46842
#> simMouse_chr6, 0, 636262, 1, 46393, 0
#> simRat_chr6, 0, 647215, 1, 46074, 0
#> Anc2, 2, 576113, 1, 8881, 42841
#> simCow_chr6, 0, 602619, 1, 40218, 0
#> simDog_chr6, 0, 593897, 1, 40949, 0
```

## Troubleshooting

On occasions where a job is being killed (eg. by `slurm`), I was able to pick it up again after a little manual manipulation of the job script of the failed task:

The idea is to append the cactus command with `--restart`.
So if for example the job running `sh/cactus/round_2/job_1/step_1.sh` failed, the original script would need updating as follows:

```sh
# original step_1.sh
cactus-blast /tmp/js/2 results/cactus/mammal_set.txt /tmp/steps-output/Anc2.cigar --root Anc2  --maxCores 4
```

```sh
# update step_1.sh
cactus-blast /tmp/js/2 results/cactus/mammal_set.txt /tmp/steps-output/Anc2.cigar --root Anc2  --maxCores 4 --restart
```

After this manual manipulation, `snakemake` should be able to resume (and hopefully run the job to completion).

## References

[Armstrong, J. *et al.* (2020)](https://doi.org/10.1038/s41586-020-2871-y) *Progressive Cactus is a multiple-genome aligner for the thousand-genome era.* Nature, 587(7833), 246–251. 

[Hickey, G. *et al.* (2013)](https://doi.org/10.1093/bioinformatics/btt128) *HAL: a hierarchical format for storing and analyzing multiple genome alignments.* Bioinformatics, 29(10), 1341–1342. 

[Kurtzer, G. M., Sochat, V., & Bauer, M. W. (2017)](https://doi.org/10.1371/journal.pone.0177459) *Singularity: Scientific containers for mobility of compute.* PLOS ONE, 12(5), e0177459. 

[Mölder, F. *et al.* (2021)](https://doi.org/10.12688/f1000research.29032.1) *Sustainable data analysis with Snakemake* (10:33). F1000Research. 
