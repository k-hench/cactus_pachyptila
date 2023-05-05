
rule cactus_prep:
    input: 'results/checkpoints/done_round_0.txt'

rule parse_cactus_config:
    output: 'results/cactus/{name}.txt'.format(name = P_NAME)
    log: "logs/cactus/parse_config.log"
    params:
      genomes = G_ALL
    script: "../../py/sm_cactus_input.py"

rule jobstore_setup:
    input: 'results/cactus/{name}.txt'.format(name = P_NAME)
    output: 'results/cactus/jobStore.img'
    params:
      ["docker://" + config['cactus_sif'], config['expected_hal_size']]
    log: "logs/cactus/jobstore_setup.log"
    script: "../../sh/sm_cactus_jobstore.sh"

rule stepwise_instructions:
    input: 
      'results/cactus/jobStore.img'
    output: "results/cactus/cactus_instructions.sh"
    params: ["docker://" + config['cactus_sif'], 'results/cactus/{name}.txt'.format(name = P_NAME)]
    log: "logs/cactus/instructions.log"
    script: "../../sh/sm_cactus_instructions.sh"

rule parse_cactus_steps:
    input: "results/cactus/cactus_instructions.sh"
    output: "results/checkpoints/done_round_0.txt"
    log: "logs/cactus/parse_instructions.log"
    shell:
      """
      Rscript --vanilla R/parse_cactus_jobs.R &> {log} && touch {output}
      """
