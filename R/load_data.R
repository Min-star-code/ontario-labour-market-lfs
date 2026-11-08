# Readers for the committed snapshot files. Each returns a tidy tibble with a
# Date column (first day of the reference month) and numeric `value`.
# Suppressed or unavailable cells (empty VALUE) are dropped, not filled.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

snap <- function(name) file.path("data", "snapshot", name)

read_statcan <- function(path) {
  read_csv(path, col_types = cols(.default = col_character()), progress = FALSE) %>%
    rename_with(~ sub("^﻿", "", .x)) %>%
    mutate(date = as.Date(paste0(REF_DATE, "-01")),
           value = as.numeric(VALUE)) %>%
    filter(!is.na(value))
}

load_lfs <- function() {
  read_statcan(snap("lfs_14100287_on_ca.csv")) %>%
    transmute(date, geo = GEO, characteristic = `Labour force characteristics`,
              age = `Age group`, value)
}

load_lfs_industry <- function() {
  read_statcan(snap("lfs_industry_14100355_on_ca.csv")) %>%
    transmute(date, geo = GEO,
              industry = `North American Industry Classification System (NAICS)`, value)
}

load_jvws_monthly <- function() {
  read_statcan(snap("jvws_monthly_14100432_on_ca.csv")) %>%
    transmute(date, geo = GEO, statistic = Statistics, value)
}

load_jvws_industry <- function() {
  read_statcan(snap("jvws_industry_14100442_on.csv")) %>%
    filter(grepl("\\[[0-9-]+\\]$", `North American Industry Classification System (NAICS)`) |
             `North American Industry Classification System (NAICS)` == "Total, all industries") %>%
    # keep 2-digit sectors only (sub-sectors have 3-digit codes)
    filter(!grepl("\\[[0-9]{3}", `North American Industry Classification System (NAICS)`)) %>%
    transmute(date, industry = `North American Industry Classification System (NAICS)`,
              statistic = Statistics, value)
}
