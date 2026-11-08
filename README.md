# Ontario Labour Market: LFS and Job Vacancy Analysis (R)

An R analysis of Ontario's labour market using Statistics Canada's **Labour Force Survey (LFS)** and **Job Vacancy and Wage Survey (JVWS)**, with a one-page briefing note.

**Briefing note:** [reports/labour_market_brief.md](reports/labour_market_brief.md)

## Questions

1. How does Ontario's unemployment rate compare with Canada's, and with before COVID-19?
2. Which age groups carry the most unemployment?
3. Which industries gained and lost jobs over the last 12 months?
4. How many unemployed people are there for each job vacancy?
5. Which industries have the most vacancies, and what wages do they offer?

## Data

| Table | Survey | What it contains |
|---|---|---|
| 14-10-0287-01 | LFS | Labour force characteristics by age group, monthly, seasonally adjusted |
| 14-10-0355-01 | LFS | Employment by industry, monthly, seasonally adjusted |
| 14-10-0432-01 | JVWS | Job vacancies, payroll employees, vacancy rate by province, monthly, seasonally adjusted |
| 14-10-0442-01 | JVWS | Vacancies and average offered hourly wage by industry, quarterly, unadjusted |

Source: Statistics Canada, used under the [Statistics Canada Open Licence](https://www.statcan.gc.ca/en/reference/licence). The snapshot in `data/snapshot/` keeps only Ontario and Canada rows (the full LFS table is about 1.2 GB) and was taken on 8 November 2026, covering LFS data to October 2026 and JVWS data to August 2026 (monthly) and 2026 Q2 (by industry).

## How to run

Requires R 4.x with `readr`, `dplyr`, `tidyr`, `ggplot2` and `testthat`.

```bash
Rscript R/fetch_snapshot.R   # optional: re-download from Statistics Canada and rebuild the snapshot
Rscript tests/test_data.R    # 9 data checks
Rscript R/analysis.R         # writes outputs/tables, outputs/figures and outputs/key_numbers.csv
```

## Data checks

`tests/test_data.R` checks that:

- each month, region, characteristic and age group has exactly one value, with no missing months since 2019;
- the published unemployment rate equals unemployed / labour force (within rounding);
- employment equals full-time plus part-time employment;
- total employment in the industry table matches the main LFS table, and goods plus services sectors add up to the total;
- the job vacancy rate equals vacancies / (vacancies + payroll employees);
- the JVWS industry file keeps only 2-digit NAICS sectors, and all rates are between 0 and 100.

## Outputs

- `outputs/key_numbers.csv` - every number quoted in the briefing note, with its period
- `outputs/tables/` - unemployment by region and age, employment change by industry, unemployed per vacancy, vacancies by industry
- `outputs/figures/` - four charts (Ontario vs. Canada unemployment, unemployment by age, industry employment change, unemployed per vacancy)

## Limitations

- LFS is a sample survey; short-term changes for small groups can be within sampling error.
- JVWS industry figures are not seasonally adjusted, so they are compared year over year only.
- JVWS was not collected from April to September 2020.
- Unemployed per vacancy combines a household survey and an employer survey and ignores skill and location mismatch.
