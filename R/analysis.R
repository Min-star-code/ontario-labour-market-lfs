# Ontario labour market analysis from the Labour Force Survey (LFS) and the
# Job Vacancy and Wage Survey (JVWS).
#
# Run from the project root:  Rscript R/analysis.R
# Reads data/snapshot/*.csv, writes outputs/tables/*.csv, outputs/figures/*.png
# and outputs/key_numbers.csv (every number quoted in the briefing note).

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

source(file.path("R", "load_data.R"))

dir.create(file.path("outputs", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)

lfs <- load_lfs()
ind <- load_lfs_industry()
jv_m <- load_jvws_monthly()
jv_q <- load_jvws_industry()

latest <- max(lfs$date)
year_ago <- seq(latest, by = "-1 year", length.out = 2)[2]
pre_covid <- as.Date("2020-02-01")
key <- list()
add_key <- function(metric, value, unit, period) {
  key[[length(key) + 1]] <<- tibble(metric = metric, value = value, unit = unit, period = period)
}
fmt_month <- function(d) format(d, "%Y-%m")

# 1. Unemployment rate: Ontario vs Canada, 15 years and over --------------------
ur <- lfs %>%
  filter(characteristic == "Unemployment rate", age == "15 years and over",
         date >= as.Date("2019-01-01")) %>%
  select(date, geo, value)

ur_wide <- ur %>% pivot_wider(names_from = geo, values_from = value)
write_csv(ur_wide, file.path("outputs", "tables", "unemployment_rate_on_ca.csv"))

on_now <- ur_wide$Ontario[ur_wide$date == latest]
ca_now <- ur_wide$Canada[ur_wide$date == latest]
on_year_ago <- ur_wide$Ontario[ur_wide$date == year_ago]
on_pre <- ur_wide$Ontario[ur_wide$date == pre_covid]
on_peak <- ur %>% filter(geo == "Ontario") %>% slice_max(value, n = 1, with_ties = FALSE)
gap <- ur_wide %>% mutate(gap = Ontario - Canada)
months_above <- gap %>% filter(date > latest - 365 * 2, gap > 0) %>% nrow()

add_key("Ontario unemployment rate", on_now, "%", fmt_month(latest))
add_key("Canada unemployment rate", ca_now, "%", fmt_month(latest))
add_key("Ontario unemployment rate a year earlier", on_year_ago, "%", fmt_month(year_ago))
add_key("Ontario unemployment rate before COVID-19", on_pre, "%", fmt_month(pre_covid))
add_key("Ontario pandemic peak unemployment rate", on_peak$value, "%", fmt_month(on_peak$date))
add_key("Months Ontario rate above Canada, last 24 months", months_above, "months",
        paste(fmt_month(latest - 365 * 2 + 31), "to", fmt_month(latest)))

p1 <- ggplot(ur, aes(date, value, colour = geo)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = c(Canada = "grey55", Ontario = "#1f5fa8")) +
  labs(title = "Unemployment rate, Ontario vs. Canada (seasonally adjusted, 15+)",
       x = NULL, y = "Percent", colour = NULL,
       caption = "Source: Statistics Canada, Labour Force Survey, Table 14-10-0287-01") +
  theme_minimal(base_size = 11) + theme(legend.position = "top")
ggsave(file.path("outputs", "figures", "fig1_unemployment_on_vs_ca.png"), p1, width = 8, height = 4.5, dpi = 150)

# 2. Youth vs core-age unemployment in Ontario ----------------------------------
age_ur <- lfs %>%
  filter(geo == "Ontario", characteristic == "Unemployment rate",
         age %in% c("15 to 24 years", "25 to 54 years", "55 years and over"),
         date >= as.Date("2019-01-01")) %>%
  select(date, age, value)
write_csv(age_ur %>% pivot_wider(names_from = age, values_from = value),
          file.path("outputs", "tables", "ontario_unemployment_by_age.csv"))

age_now <- age_ur %>% filter(date == latest)
age_2019 <- age_ur %>% filter(format(date, "%Y") == "2019") %>%
  group_by(age) %>% summarise(value = mean(value), .groups = "drop")
for (a in c("15 to 24 years", "25 to 54 years")) {
  add_key(paste("Ontario unemployment rate,", a), age_now$value[age_now$age == a], "%", fmt_month(latest))
  add_key(paste("Ontario unemployment rate,", a, "2019 average"), round(age_2019$value[age_2019$age == a], 1), "%", "2019")
}

p2 <- ggplot(age_ur, aes(date, value, colour = age)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = c("15 to 24 years" = "#c0392b", "25 to 54 years" = "#1f5fa8",
                                 "55 years and over" = "grey55")) +
  labs(title = "Ontario unemployment rate by age group (seasonally adjusted)",
       x = NULL, y = "Percent", colour = NULL,
       caption = "Source: Statistics Canada, Labour Force Survey, Table 14-10-0287-01") +
  theme_minimal(base_size = 11) + theme(legend.position = "top")
ggsave(file.path("outputs", "figures", "fig2_ontario_unemployment_by_age.png"), p2, width = 8, height = 4.5, dpi = 150)

# 3. Employment by industry, Ontario: 12-month change and change since Feb 2020 --
aggregates <- c("Total employed, all industries", "Goods-producing sector",
                "Services-producing sector", "Wholesale and retail trade [41, 44-45]")
ind_on <- ind %>% filter(geo == "Ontario")
ind_change <- ind_on %>%
  filter(date %in% c(latest, year_ago, pre_covid)) %>%
  select(industry, date, value) %>%
  mutate(when = case_when(date == latest ~ "now", date == year_ago ~ "year_ago", TRUE ~ "pre_covid")) %>%
  select(-date) %>%
  pivot_wider(names_from = when, values_from = value) %>%
  mutate(change_12m = round(now - year_ago, 1),
         pct_12m = round(100 * (now - year_ago) / year_ago, 1),
         change_since_feb2020 = round(now - pre_covid, 1),
         pct_since_feb2020 = round(100 * (now - pre_covid) / pre_covid, 1)) %>%
  arrange(desc(change_12m))
write_csv(ind_change, file.path("outputs", "tables", "ontario_employment_by_industry_change.csv"))

total <- ind_change %>% filter(industry == "Total employed, all industries")
add_key("Ontario total employment", total$now, "thousand persons", fmt_month(latest))
add_key("Ontario employment change over 12 months", round(total$change_12m, 1), "thousand persons",
        paste(fmt_month(year_ago), "to", fmt_month(latest)))
add_key("Ontario employment change since Feb 2020", round(total$pct_since_feb2020, 1), "%",
        paste(fmt_month(pre_covid), "to", fmt_month(latest)))

sectors <- ind_change %>% filter(!industry %in% aggregates)
top_gain <- sectors %>% slice_max(change_12m, n = 1)
top_loss <- sectors %>% slice_min(change_12m, n = 1)
add_key(paste("Largest 12-month gain:", top_gain$industry), round(top_gain$change_12m, 1), "thousand persons", fmt_month(latest))
add_key(paste("Largest 12-month loss:", top_loss$industry), round(top_loss$change_12m, 1), "thousand persons", fmt_month(latest))

p3 <- sectors %>%
  mutate(industry = sub(" \\[.*\\]$", "", industry),
         industry = reorder(industry, change_12m)) %>%
  ggplot(aes(change_12m, industry, fill = change_12m > 0)) +
  geom_col() +
  scale_fill_manual(values = c(`TRUE` = "#1f5fa8", `FALSE` = "#c0392b"), guide = "none") +
  labs(title = sprintf("Ontario employment change by industry, %s to %s", fmt_month(year_ago), fmt_month(latest)),
       x = "Change in employment (thousands)", y = NULL,
       caption = "Source: Statistics Canada, Labour Force Survey, Table 14-10-0355-01 (seasonally adjusted)") +
  theme_minimal(base_size = 10)
ggsave(file.path("outputs", "figures", "fig3_ontario_industry_change.png"), p3, width = 8, height = 5, dpi = 150)

# 4. Labour market tightness: unemployed persons per job vacancy, Ontario ---------
unemployed <- lfs %>%
  filter(geo == "Ontario", characteristic == "Unemployment", age == "15 years and over") %>%
  transmute(date, unemployed = value * 1000)
vacancies <- jv_m %>% filter(geo == "Ontario", statistic == "Job vacancies") %>%
  transmute(date, vacancies = value)
vac_rate <- jv_m %>% filter(statistic == "Job vacancy rate") %>%
  select(date, geo, value) %>% pivot_wider(names_from = geo, values_from = value)

tight <- inner_join(unemployed, vacancies, by = "date") %>%
  mutate(unemployed_per_vacancy = unemployed / vacancies)
write_csv(tight, file.path("outputs", "tables", "ontario_unemployed_per_vacancy.csv"))

jv_latest <- max(tight$date)
tight_now <- tight %>% filter(date == jv_latest)
tight_min <- tight %>% slice_min(unemployed_per_vacancy, n = 1, with_ties = FALSE)
add_key("Ontario job vacancies", tight_now$vacancies, "vacancies", fmt_month(jv_latest))
add_key("Ontario unemployed persons per vacancy", round(tight_now$unemployed_per_vacancy, 1), "ratio", fmt_month(jv_latest))
add_key("Lowest unemployed persons per vacancy", round(tight_min$unemployed_per_vacancy, 1), "ratio", fmt_month(tight_min$date))
tight_recent_max <- tight %>% filter(date >= as.Date("2023-01-01")) %>% slice_max(unemployed_per_vacancy, n = 1, with_ties = FALSE)
add_key("Highest unemployed persons per vacancy since 2023", round(tight_recent_max$unemployed_per_vacancy, 1), "ratio", fmt_month(tight_recent_max$date))
missing_jv <- setdiff(seq(min(tight$date), jv_latest, by = "month"), tight$date)
add_key("Months with no JVWS estimate (survey paused)", length(missing_jv), "months",
        paste(fmt_month(as.Date(min(missing_jv))), "to", fmt_month(as.Date(max(missing_jv)))))
add_key("Ontario job vacancy rate", vac_rate$Ontario[vac_rate$date == jv_latest], "%", fmt_month(jv_latest))
add_key("Canada job vacancy rate", vac_rate$Canada[vac_rate$date == jv_latest], "%", fmt_month(jv_latest))

# Keep the months JVWS did not publish as NA so the line shows a gap instead of bridging it.
p4 <- tight %>% tidyr::complete(date = seq(min(date), max(date), by = "month")) %>%
  ggplot(aes(date, unemployed_per_vacancy)) +
  geom_line(linewidth = 0.8, colour = "#1f5fa8") +
  labs(title = "Ontario: unemployed persons per job vacancy (seasonally adjusted)",
       subtitle = "Gap: JVWS was not collected for part of 2020",
       x = NULL, y = "Unemployed per vacancy",
       caption = "Sources: Statistics Canada, LFS Table 14-10-0287-01 and JVWS Table 14-10-0432-01") +
  theme_minimal(base_size = 11)
ggsave(file.path("outputs", "figures", "fig4_ontario_unemployed_per_vacancy.png"), p4, width = 8, height = 4.5, dpi = 150)

# 5. Vacancies and offered wages by industry, Ontario, latest quarter -------------
q_latest <- max(jv_q$date)
q_year_ago <- seq(q_latest, by = "-1 year", length.out = 2)[2]
jv_ind <- jv_q %>%
  filter(date %in% c(q_latest, q_year_ago), industry != "Total, all industries") %>%
  select(date, industry, statistic, value) %>%
  pivot_wider(names_from = statistic, values_from = value) %>%
  mutate(when = if_else(date == q_latest, "now", "year_ago")) %>%
  select(-date) %>%
  pivot_wider(names_from = when, values_from = c(`Payroll employees`, `Job vacancies`, `Job vacancy rate`,
                                                  `Average offered hourly wage`)) %>%
  mutate(vacancy_change_pct = round(100 * (`Job vacancies_now` / `Job vacancies_year_ago` - 1), 1)) %>%
  arrange(desc(`Job vacancies_now`))
write_csv(jv_ind, file.path("outputs", "tables", "ontario_vacancies_by_industry.csv"))

top_vac <- jv_ind %>% slice_max(`Job vacancies_now`, n = 1)
top_rate <- jv_ind %>% slice_max(`Job vacancy rate_now`, n = 1)
q_label <- paste0(format(q_latest, "%Y"), " Q", (as.integer(format(q_latest, "%m")) - 1) %/% 3 + 1)
add_key(paste("Most vacancies:", top_vac$industry), top_vac$`Job vacancies_now`, "vacancies", q_label)
add_key(paste("Highest vacancy rate:", top_rate$industry), top_rate$`Job vacancy rate_now`, "%", q_label)
total_q <- jv_q %>% filter(industry == "Total, all industries", date %in% c(q_latest, q_year_ago),
                           statistic == "Job vacancies") %>% arrange(date)
add_key("Ontario vacancies, all industries (unadjusted)", total_q$value[2], "vacancies", q_label)
add_key("Ontario vacancies, all industries, change over a year", round(100 * (total_q$value[2] / total_q$value[1] - 1), 1), "%", q_label)

key_tbl <- bind_rows(key)
write_csv(key_tbl, file.path("outputs", "key_numbers.csv"))
print(key_tbl, n = Inf, width = 200)
