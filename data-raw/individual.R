## code to prepare `individual` dataset goes here
## Setup ----
library(dplyr)
source(here::here("R", "geolocate.R"))

## Combine individual tables ----
## Create paths to inputs
raw_data_path <- here::here("data-raw", 
                            "wood-survey-data-master")

individual_paths <- fs::dir_ls( # dir_ls creates list of files in "individual" folder
  fs::path(raw_data_path, "individual") # tells dir_ls where to find the files
  )

# read in all individual tables into one
individual <- purrr::map(.x = individual_paths, 
                         ~readr::read_csv(
                           .x,
                           col_types = readr::cols(.default = "c"), 
                           show_col_types = FALSE)
) %>% 
  purrr::list_rbind() %>% 
  readr::type_convert()

individual %>% 
  readr::write_csv(
    file = fs::path(raw_data_path, "vst_individuals.csv")
  )

# Combine NEON data tables ----
# read in additional tables
maptag <- readr::read_csv(
  fs::path(raw_data_path, 
           "vst_mappingandtagging.csv")
) %>% 
  select(-eventID)

perplot <- readr::read_csv(
  fs::path(raw_data_path, 
           "vst_perplotperyear.csv"),
  show_col_types = FALSE
) %>% 
  select(-eventID)

# Left join tables to individual
individual %<>% 
  left_join(maptag,
            by = "individualID", 
            suffix = c("", "_map")) %>% 
  left_join(perplot,
            by = "plotID",
            suffix = c("", "_ppl")) %>% 
  assertr::assert(
    assertr::not_na, stemDistance, stemAzimuth, pointID,
    decimalLatitude, decimalLongitude)

# Geolocate individuals ----
individual <- individual %>%  mutate(
  stemLat = get_stem_location(
    decimalLongitude, decimalLatitude,
    stemAzimuth, stemDistance
    )$lat,
  stemLon = get_stem_location(
    decimalLongitude, decimalLatitude,
    stemAzimuth, stemDistance
  )$lon
) %>% 
  janitor::clean_names()

# create data directory
fs::dir_create(here::here("data"))

# write out analytic file
individual %>%
  janitor::clean_names() %>%
  readr::write_csv(here::here("data", "individual.csv"))

