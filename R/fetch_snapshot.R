# Download the Statistics Canada tables used in this project and keep only the
# Ontario / Canada rows the analysis needs, so the committed snapshot stays small.
#
# Run from the project root:  Rscript R/fetch_snapshot.R
# Tables (all public, Statistics Canada Open Licence):
#   14-10-0287-01  Labour Force Survey characteristics, monthly, seasonally adjusted
#   14-10-0355-01  LFS employment by industry, monthly, seasonally adjusted
#   14-10-0432-01  JVWS job vacancies by province, monthly, seasonally adjusted
#   14-10-0442-01  JVWS job vacancies and offered wages by industry, quarterly, unadjusted

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

raw_dir <- file.path("data", "raw")
snap_dir <- file.path("data", "snapshot")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(snap_dir, recursive = TRUE, showWarnings = FALSE)

download_table <- function(pid) {
  csv <- file.path(raw_dir, pid, paste0(pid, ".csv"))
  if (!file.exists(csv)) {
    dir.create(file.path(raw_dir, pid), showWarnings = FALSE)
    zip <- file.path(raw_dir, pid, paste0(pid, ".zip"))
    url <- sprintf("https://www150.statcan.gc.ca/n1/tbl/csv/%s-eng.zip", pid)
    options(timeout = 1200)
    download.file(url, zip, mode = "wb", quiet = TRUE)
    unzip(zip, exdir = file.path(raw_dir, pid))
    unlink(zip)
  }
  csv
}

# Read a large table in chunks, keeping only rows that pass `keep`.
filter_table <- function(pid, keep, out_name) {
  csv <- download_table(pid)
  rows <- read_csv_chunked(
    csv,
    DataFrameCallback$new(function(chunk, pos) keep(chunk)),
    chunk_size = 500000,
    col_types = cols(.default = col_character()),
    progress = FALSE
  )
  write_csv(rows, file.path(snap_dir, out_name), na = "")
  message(sprintf("%s: kept %d rows -> %s", pid, nrow(rows), out_name))
}

on_ca <- c("Ontario", "Canada")

filter_table("14100287", function(d) filter(d,
  GEO %in% on_ca, Gender == "Total - Gender",
  Statistics == "Estimate", `Data type` == "Seasonally adjusted"),
  "lfs_14100287_on_ca.csv")

filter_table("14100355", function(d) filter(d,
  GEO %in% on_ca, Statistics == "Estimate", `Data type` == "Seasonally adjusted"),
  "lfs_industry_14100355_on_ca.csv")

filter_table("14100432", function(d) filter(d, GEO %in% on_ca),
  "jvws_monthly_14100432_on_ca.csv")

filter_table("14100442", function(d) filter(d, GEO == "Ontario"),
  "jvws_industry_14100442_on.csv")
