### prep data 

```sh
wget https://raw.githubusercontent.com/ComparativeGenomicsToolkit/cactus/master/examples/evolverMammals.txt
```

### setup of the cactus working directory

```sh
readonly CACTUS_IMAGE=docker://quay.io/comparative-genomics-toolkit/cactus:v2.5.1
readonly JOBSTORE_IMAGE=jobStore.img
readonly SEQFILE=evolverMammals.txt
readonly OUTPUTHAL=evolverMammals.hal
readonly CACTUS_OPTIONS='--root mr'

RUN_ID='test'

readonly CACTUS_SCRATCH=scratch/cactus-${RUN_ID}

restart=''
mkdir -p -m 777 ${CACTUS_SCRATCH}/upper ${CACTUS_SCRATCH}/work
truncate -s 300M "${JOBSTORE_IMAGE}"
apptainer exec --bind $(pwd) ${CACTUS_IMAGE} mkfs.ext3 -d ${CACTUS_SCRATCH} "${JOBSTORE_IMAGE}"

mkdir -m 700 -p ${CACTUS_SCRATCH}/tmp
mkdir cactus_wd
```

### step by step preparation

generating the stepwise instructions

```sh
apptainer exec --cleanenv \
  --overlay ${JOBSTORE_IMAGE} \
  --bind ${CACTUS_SCRATCH}/tmp:/tmp,$(pwd) \
  --env PYTHONNOUSERSITE=1 \
  ${CACTUS_IMAGE} \
  cactus-prepare \
  "${SEQFILE}" \
  --outDir /tmp/steps-output \
  --outSeqFile /tmp/steps-output/"${SEQFILE}" \
  --outHal /tmp/steps-output/"${OUTPUTHAL}" \
  --jobStore /tmp/js > cactus_instructions.sh
```

parse cactus jobs / rounds

```sh
Rscript --vanilla R/parse_cactus_jobs.R
```

this distributes the steps over separate `sh` scripts grouped by round:

```
sh/
└── cactus
    ├── round_1
    │   └── job_1.sh
    ├── round_2
    │   ├── job_1.sh
    │   └── job_2.sh
    ├── round_3
    │   └── job_1.sh
    ├── round_4
    │   └── job_1.sh
    └── round_5
        └── job_1.sh
```

It also creates a `tsv` file to be used for the `snakemake` management of the execution of the individual scripts:

## snakemake execution

```sh
snakemake -c 1
```