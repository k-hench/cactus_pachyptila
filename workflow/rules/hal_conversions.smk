"""
snakemake --rerun-triggers mtime -n -R convert_hal

snakemake --jobs 50 \
  --latency-wait 30 \
  -p \
  --default-resources mem_mb=10240 threads=1 \
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

rename_data = pd.read_table('data/genomes_alias.tsv', usecols=[0,1], names=['old', 'new'])

def get_new_name(nm):
    return( rename_data["new"][ rename_data["old"] == nm ].values[0] )


rule convert_hal:
    input: 
      maf = "results/maf/{name}.maf".format(name = P_NAME),
      bed = "results/coverage/collapsed/{name}.collapsed.bed.gz".format(name = P_NAME)

rule hal_rename_genomes:
    input:
      hal = 'results/cactus/{name}.hal',
      tsv = 'data/genomes_alias.tsv'
    output:
      check = touch( 'results/checkpoints/hal_{name}_genome_rename.check' )
    container: c_cactus
    shell:
      """
      halRenameGenomes  {input.hal} {input.tsv}
      """

rule hal_to_maf:
    input:
      hal = 'results/cactus/{name}.hal',
      check = 'results/checkpoints/hal_{name}_genome_rename.check'
    output:
      maf = "results/maf/{name}.maf"
    log: "logs/hal_to_maf_{name}.log"
    params:
      sif = c_cactus,
      js = "results/cactus/scratch/{name}/",
      local_js = "js_{name}",
      run = "run_{name}",
      g_updated = get_new_name(G_REF)
    resources:
      mem_mb=40960
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
        --refGenome {params.g_updated} \
        --dupeMode single \
        --filterGapCausingDupes \
        --chunkSize 1000000 \
        --noAncestors \
        --maxDisk 200G 2> {log}
      """

rule alignment_coverage:
    input:
      hal = 'results/cactus/{name}.hal'.format(name = P_NAME)
    output:
      wig = "results/coverage/wig/{name}.wig.gz"
    params:
      prefix = "results/coverage/wig/{name}.wig",
      ref_new = get_new_name(G_REF)
    container: c_cactus
    shell:
      """
      halAlignmentDepth \
        {input.hal} \
        {params.ref_new} \
        --noAncestors \
        --outWiggle {params.prefix}
      gzip {params.prefix}
      """

# ultimately we want a bed file as mask, so we convert the wig to bed format
rule wig_to_bed:
    input:
      wig = "results/coverage/wig/{name}.wig.gz"
    output:
      bed = "results/coverage/raw/{name}.bed.gz" 
    container: c_conda
    conda: "bedops"
    shell:
      """
      zcat {input.wig} | wig2bed | gzip > {output.bed}
      """

# unfortunetely, the original bed is single bp elements,
# so we collapse them into chunks of equal coverage 
rule collapse_cov_bed:
    input:
      bed = "results/coverage/raw/{name}.bed.gz" 
    output:
      bed = "results/coverage/collapsed/{name}.collapsed.bed.gz"
    log: "logs/collapse_cov_bed_{name}.log"
    container: c_conda
    conda: "r_tidy"
    shell:
      """
      Rscript --vanilla R/collapse_bed_coverage.R {input.bed} {output.bed} &>> {log}
      """
