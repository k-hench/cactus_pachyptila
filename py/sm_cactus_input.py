import pandas as pd

f = open( 'results/cactus/' + snakemake.config["alignment_name"] + ".txt", "a")

f.writelines('"' + snakemake.config["speciesTree"] + '"\n\n')

for x in snakemake.params["genomes"]:
  f.writelines(x + ' data/' + x + '.fa.gz\n')

f.close()