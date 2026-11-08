# Data checks for the snapshot. Run from the project root:  Rscript tests/test_data.R

suppressPackageStartupMessages({
  library(testthat)
  library(dplyr)
  library(tidyr)
})
source(file.path("R", "load_data.R"))

lfs <- load_lfs()
ind <- load_lfs_industry()
jv_m <- load_jvws_monthly()
jv_q <- load_jvws_industry()

test_that("one value per month, geography, characteristic and age group", {
  dup <- lfs %>% count(date, geo, characteristic, age) %>% filter(n > 1)
  expect_equal(nrow(dup), 0)
})

test_that("snapshot covers Ontario and Canada with no missing months since 2019", {
  expect_setequal(unique(lfs$geo), c("Canada", "Ontario"))
  months <- lfs %>% filter(date >= as.Date("2019-01-01"), characteristic == "Unemployment rate",
                           age == "15 years and over", geo == "Ontario") %>% pull(date)
  expected <- seq(as.Date("2019-01-01"), max(months), by = "month")
  expect_equal(sort(months), expected)
})

test_that("published unemployment rate matches unemployed / labour force", {
  check <- lfs %>%
    filter(characteristic %in% c("Unemployment", "Labour force", "Unemployment rate"),
           age == "15 years and over") %>%
    pivot_wider(names_from = characteristic, values_from = value) %>%
    mutate(diff = abs(100 * Unemployment / `Labour force` - `Unemployment rate`))
  expect_lt(max(check$diff), 0.1)
})

test_that("employment equals full-time plus part-time employment", {
  check <- lfs %>%
    filter(characteristic %in% c("Employment", "Full-time employment", "Part-time employment"),
           age == "15 years and over") %>%
    pivot_wider(names_from = characteristic, values_from = value) %>%
    mutate(diff = abs(Employment - `Full-time employment` - `Part-time employment`))
  expect_lt(max(check$diff), 0.2)
})

test_that("industry totals in Table 14-10-0355 match total employment in Table 14-10-0287", {
  total_ind <- ind %>% filter(industry == "Total employed, all industries") %>% select(date, geo, a = value)
  total_lfs <- lfs %>% filter(characteristic == "Employment", age == "15 years and over") %>%
    select(date, geo, b = value)
  joined <- inner_join(total_ind, total_lfs, by = c("date", "geo"))
  expect_gt(nrow(joined), 500)
  expect_lt(max(abs(joined$a - joined$b)), 0.2)
})

test_that("goods + services sectors add up to total employment", {
  check <- ind %>%
    filter(industry %in% c("Total employed, all industries", "Goods-producing sector", "Services-producing sector")) %>%
    pivot_wider(names_from = industry, values_from = value) %>%
    mutate(diff = abs(`Total employed, all industries` - `Goods-producing sector` - `Services-producing sector`))
  expect_lt(max(check$diff), 0.2)
})

test_that("job vacancy rate matches vacancies / (vacancies + payroll employees)", {
  check <- jv_m %>% pivot_wider(names_from = statistic, values_from = value) %>%
    mutate(diff = abs(100 * `Job vacancies` / (`Job vacancies` + `Payroll employees`) - `Job vacancy rate`))
  expect_lt(max(check$diff, na.rm = TRUE), 0.06)
})

test_that("JVWS industry file keeps only 2-digit NAICS sectors plus the total", {
  codes <- unique(jv_q$industry)
  expect_true("Total, all industries" %in% codes)
  expect_false(any(grepl("\\[[0-9]{3}", codes)))
  expect_gte(length(codes), 18)
})

test_that("rates are within 0-100 percent", {
  rates <- lfs %>% filter(grepl("rate", characteristic))
  expect_true(all(rates$value >= 0 & rates$value <= 100))
})
