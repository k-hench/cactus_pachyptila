readonly CACTUS_IMAGE=$( echo "${snakemake_params}" | awk '{print $1}')
readonly JOBSTORE_SZ=$( echo "${snakemake_params}" | awk '{print $2}')
readonly JOBSTORE_IMAGE=${snakemake_output}
readonly SEQFILE=${snakemake_input}
readonly RUN_ID=${SEQFILE%.txt}
readonly CACTUS_SCRATCH=results/cactus/scratch/cactus-${RUN_ID}

echo "${CACTUS_IMAGE}" &> "${snakemake_log[0]}"
echo "==================" &>> "${snakemake_log[0]}"
echo ${JOBSTORE_SZ} &>> "${snakemake_log[0]}"

restart=''
mkdir -p -m 777 ${CACTUS_SCRATCH}/upper ${CACTUS_SCRATCH}/work
truncate -s ${JOBSTORE_SZ} "${JOBSTORE_IMAGE}"
apptainer exec --bind $(pwd) ${CACTUS_IMAGE} mkfs.ext3 -d ${CACTUS_SCRATCH} "${JOBSTORE_IMAGE}"

mkdir -m 700 -p ${CACTUS_SCRATCH}/tmp
mkdir -p results/cactus/cactus_wd
