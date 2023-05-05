job_file = "results/cactus/job_inventory.tsv"
rounds = pd.read_table(job_file)['round']
n_rounds = rounds.max()
n_jobs = pd.read_table(job_file)['n_jobs']

rule cactus_stepwise:
    input: "results/checkpoints/done_round_{nr}.txt".format(nr = n_rounds)

def collect_jobs(wildcards):
  rnd = int(wildcards.nr)
  n_j = n_jobs[rnd - 1]
  j_list = (np.arange(0, n_j) + 1)
  j_checks = [ 'results/checkpoints/done_round_' + str(rnd) + "_j" + str(i) + ".txt" for i in j_list ]
  return(j_checks)

def previous_round(wildcards):
  rnd = int(wildcards.nr)
  return("results/checkpoints/done_round_" + str(rnd-1) + ".txt")

rule round_completed:
    input: lambda wc: collect_jobs(wc)
    output: "results/checkpoints/done_round_{nr}.txt"
    shell:
      '''
      touch {output}
      '''

def parse_job(wildcards):
  # >> parse the job path <<
  # It is not genreally clear how the round and 
  # job fromat looks like: they are numbered with 
  # padding zeros depending on the overall number
  # of rounds/jobs.
  # The first round might therefore be for example
  # either "round_1" or round "round_001".
  rnd = int(wildcards.nr)
  job = int(wildcards.job)
  job_tbl = pd.read_table("results/cactus/job_list.tsv")
  cur_rnd = ((job_tbl["round"][job_tbl["round_idx"] == rnd]).reset_index(drop = True))[0]
  cur_job = ((job_tbl["job"][job_tbl["round_idx"] == rnd]).reset_index(drop = True))[job - 1]
  return("sh/cactus/" + cur_rnd + "/" + cur_job)
  # parse_job(pd.Series([2, 1], index = ["nr", "job"]))

rule single_job:
    input:
      previous_round = lambda wc: previous_round(wc),
      job_script = lambda wc: parse_job(wc)
    output: "results/checkpoints/done_round_{nr}_j{job}.txt"
    params:
      sif = "docker://" + config['cactus_sif'],
      seqfile = 'results/cactus/{name}.txt'.format(name = P_NAME),
      jobstore = JOBSTORE_PATH
    log: "logs/cactus/jobs/round_{nr}_j{job}.log"
    shell:
      '''
      readonly CACTUS_IMAGE={params.sif} 
      readonly SEQFILE={params.seqfile}
      readonly SEQNAME=${{SEQFILE##*/}}
      readonly RUN_ID=${{SEQNAME%.txt}}
      readonly CACTUS_SCRATCH=results/cactus/scratch/${{RUN_ID}}

      echo "file: " ${{SEQFILE}} &>> {log}
      echo "==================" &>> {log}
      echo "img: "${{CACTUS_IMAGE}} &>> {log}
      echo "==================" &>> {log}
      echo "round {wildcards.nr}; job {wildcards.job}" &>> {log}
      echo "==================" &>> {log}

      apptainer exec --cleanenv \
        --overlay {params.jobstore} \
        --bind ${{CACTUS_SCRATCH}}/tmp:/tmp,$(pwd) \
        --env PYTHONNOUSERSITE=1 \
        {params.sif} \
        bash {input.job_script} &>> {log}

      touch {output}
      '''