# samtools faidx <genome_name.fa.gz>
library(tidyverse)
library(here)

read_fai <- \(file){
  read_tsv(file,
           col_names = c("name", "length", "offset", "linebases", "linewidth"))
}

data <- read_fai(here("data/pa_de_D2102046010.v3_masked.fa.gz.fai"))

data |> 
  ggplot(aes(x = log10(length))) +
  geom_histogram()

data |> 
  arrange(length) |> 
  mutate(length_cum = cumsum(length)) |> 
  ggplot(aes(x = -log10(length),
             y = length_cum)) +
  geom_line() +
  geom_point() +
  geom_hline(color = "red", yintercept = sum(data$length)/2) +
  scale_y_continuous(labels = \(x){sprintf("%.1f", x*1e-9)})

data |> 
  filter(length < 1e3)
