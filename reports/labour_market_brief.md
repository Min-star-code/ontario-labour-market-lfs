# Briefing Note: Ontario's labour market has loosened, and the slack falls on young workers

**Prepared by:** Mincheng Li | **Data as of:** October 2026 Labour Force Survey (released 6 November 2026)

## Issue

Ontario's unemployment rate has stayed above the national rate for two years. This note uses Statistics Canada's Labour Force Survey (LFS) and Job Vacancy and Wage Survey (JVWS) to show where the slack is: by age group, by industry, and against the number of open jobs.

## Background

All figures are seasonally adjusted estimates for people aged 15 and over unless stated. The LFS is a monthly household survey; the JVWS is an employer survey, so the two are combined only as a ratio. Every figure below is produced by `R/analysis.R` and listed in `outputs/key_numbers.csv`. The snapshot passes 9 automated checks, such as the published unemployment rate matching unemployed persons divided by the labour force.

## Key findings

1. **Ontario is above the national rate.** Ontario's unemployment rate was 7.3% in October 2026, against 6.7% for Canada, and it has been above Canada's rate in each of the last 24 months. It is down from 7.6% a year earlier but still well above the 5.6% of February 2020.
2. **Young people carry the most slack.** The rate for 15 to 24 year olds was 16.1%, compared with an average of 11.8% in 2019. For core-age workers (25 to 54) it was 6.1%, against 4.5% in 2019.
3. **Job growth is narrow.** Ontario added 25,400 jobs over the year (+0.3%). Health care and social assistance added 61,200, while retail trade lost 51,700, accommodation and food services 37,900 and wholesale trade 27,200, which are sectors that often hire young workers.
4. **There are far more job seekers than openings.** In August 2026 there were 3.6 unemployed people for each of Ontario's 171,385 job vacancies. This is down from a recent high of 4.1 in October 2025, but far above the low of 1.1 in July 2022. Ontario's vacancy rate (2.5%) is below Canada's (2.8%).
5. **Openings are concentrated in a few sectors.** In 2026 Q2, health care had the most vacancies (31,390), though 16.8% fewer than a year earlier. Accommodation and food services had the highest vacancy rate (4.4%) but some of the lowest offered wages ($19.20 an hour on average).

## Considerations

- LFS estimates are based on a sample; monthly changes for single industries or age groups can fall within sampling error. Twelve-month changes and longer trends are more reliable.
- The vacancy figures by industry (Table 14-10-0442) are not seasonally adjusted, so they are compared with the same quarter a year earlier only.
- JVWS was not collected from April to September 2020, so the vacancy ratio has a gap in that period.
- Unemployed persons per vacancy treats all job seekers and openings as interchangeable; it does not reflect differences in skills or location.

## Suggested next steps

- Break youth unemployment down further (students vs. non-students, 15 to 19 vs. 20 to 24) to see who is most affected.
- Compare Ontario's economic regions (JVWS Table 14-10-0441) to check whether the slack is concentrated in particular areas, such as Toronto or Windsor.
