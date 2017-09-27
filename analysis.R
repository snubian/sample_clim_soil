library(tidyverse)
library(magrittr)
library(stringr)
library(raster)

rm(list = ls())

# occurrence data
data <- read_csv("~/Work/extinction_risk/output/occurrence/occurrence_clean.csv")

# sample taxa
taxaSample <-
  data %>%
  dplyr::select(scientificName) %>%
  table %>%
  data.frame %>%
  setNames(c("taxon", "freq")) %>%
  filter(freq >= 50) %>%
  sample_n(200) %>%
  arrange(taxon)

# sample occurrence data
dataSample <-
  data %>%
  filter(scientificName %in% taxaSample$taxon) %>%
  dplyr::select(scientificName, longitude, latitude) %>%
  setNames(c("taxon", "longitude", "latitude")) %>%
  arrange(taxon)

# climate and soil data filenames
fn <- c(list.files("data/bioclim/", "\\.tif$", full.names = TRUE),
        list.files("data/soil/", "\\.tif$", full.names = TRUE)
)

# for each file, extract point data from the raster and append column to sample data
for (f in fn) {
  
  message(f)

  dataSample %<>%
    dplyr::select(longitude, latitude) %>%
    extract(f %>% raster, .) %>%
    cbind(dataSample, .)

  # give new column a name based on the source raster filename
  colnames(dataSample)[ncol(dataSample)] <-
    ifelse(grepl("bioclim", f),
           basename(f) %>% str_sub(7, -5),
           basename(f) %>% str_sub(1, 3) %>% tolower %>% paste0("soil_", .)
           )
  
}

# write output
dataSample %>%
  write_csv("output/clim_soil_sample.csv")
  