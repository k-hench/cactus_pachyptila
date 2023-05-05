readonly CACTUS_IMAGE=$( echo "${snakemake_params}" | awk '{print $1}')
readonly SEQFILE=$( echo "${snakemake_params}" | awk '{print $2}')
readonly JOBSTORE_IMAGE="${snakemake_input}"
readonly CACTUS_OPTIONS='--root mr'
readonly RUN_ID=${SEQFILE%.txt}
readonly CACTUS_SCRATCH=results/cactus/scratch/cactus-${RUN_ID}

echo "store: ""${JOBSTORE_IMAGE}" &> "${snakemake_log[0]}"
echo "==================" &>> "${snakemake_log[0]}"
echo "file: " ${SEQFILE} &>> "${snakemake_log[0]}"
echo "==================" &>> "${snakemake_log[0]}"
echo "img: "${CACTUS_IMAGE} &>> "${snakemake_log[0]}"

apptainer exec --cleanenv \
  --overlay ${JOBSTORE_IMAGE} \
  --bind ${CACTUS_SCRATCH}/tmp:/tmp,$(pwd) \
  --env PYTHONNOUSERSITE=1 \
  ${CACTUS_IMAGE} \
  cactus-prepare \
  $(pwd)/${SEQFILE} \
  --outDir /tmp/steps-output \
  --outSeqFile ${SEQFILE} \
  --outHal /tmp/steps-output/${OUTPUTHAL} \
  --jobStore /tmp/js >  ${snakemake_output}