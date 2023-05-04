import os
import numpy as np
import pandas as pd

job_file = "data/job_inventory.tsv"

rounds = pd.read_table(job_file)['round']
n_rounds = rounds.max()
n_jobs = pd.read_table(job_file)['n_jobs']

rule all:
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

rule single_job:
    input: lambda wc: previous_round(wc)
    output: "results/checkpoints/done_round_{nr}_j{job}.txt"
    shell:
      '''
      touch {output}
      '''

rule start:
    output: 'results/checkpoints/done_round_0.txt'
    shell: "touch {output}"