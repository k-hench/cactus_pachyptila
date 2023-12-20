"""
snakemake --configfile workflow/config.yml --rerun-triggers mtime -n -R convert_hal

snakemake --jobs 50 \
  --configfile workflow/config.yml \
  --latency-wait 30 \
  -p \
  --default-resources mem_mb=51200 threads=1 \
  --use-singularity \
  --singularity-args "--bind $CDATA" \
  --use-conda \
  --rerun-triggers mtime \
  --cluster '
    sbatch \
      --export ALL \
      -n {threads} \
      -e logs/{name}.{jobid}.err \
      -o logs/{name}.{jobid}.out \
      --mem={resources.mem_mb}' \
      --jn job_c.{name}.{jobid}.sh \
      -R convert_hal
"""

TIP_SPECS = ",".join(G_QUERY)
MSCAFS = [ "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "x"]
# with open('data/scaffolds.txt') as f:
#     MSCAFS = f.read().splitlines()

rule convert_hal:
    input: 
      maf = expand("results/maf/{name}_{mscaf}.maf", name = P_NAME, mscaf = MSCAFS)

rule hal_to_maf:
    input:
      hal = 'results/cactus/{name}.hal'
    output:
      maf = "results/maf/{name}_{mscaf}.maf"
    log: "logs/hal_to_maf_{name}_{mscaf}.log"
    params:
      sif = c_cactus,
      js = "results/cactus/scratch/{name}/",
      local_js = "js_{name}_{mscaf}",
      run = "run_{name}_{mscaf}"
    shell:
      """
      readonly CACTUS_IMAGE={params.sif} 
      readonly CACTUS_SCRATCH={params.js}

      mkdir -p {params.js}{params.run}

      apptainer exec --cleanenv \
        --fakeroot --overlay ${{CACTUS_SCRATCH}} \
        --bind ${{CACTUS_SCRATCH}}/tmp:/tmp,{params.js}{params.run}:/run,$(pwd),{s_bind_paths} \
        --env PYTHONNOUSERSITE=1 \
        {params.sif} \
        cactus-hal2maf \
        /tmp/{params.local_js} \
        {input.hal} \
        {output.maf} \
        --refGenome {G_REF} \
        --refSequence {wildcards.mscaf} \
        --dupeMode single \
        --filterGapCausingDupes \
        --chunkSize 1000000 \
        --noAncestors 2> {log}
      """
