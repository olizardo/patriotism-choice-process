# Replication Package: *Patriotism as a Choice Process: National Pride After 9/11*

Omar Lizardo (UCLA). Accepted at *Social Psychology Quarterly* (Manuscript ID SPQ-26-0082).

This repository contains the data-analysis pipeline that generates the numerical results, tables, and figures reported in the paper.

## Contents

```
scripts/
  00_utils.R                          Shared helpers: GSS loading and cleaning, table formatting
  generate_tables.R                   Tables 2-4 (regression tables) + numerical audit of text claims
  generate_descriptives.R             Table 1 (descriptive statistics)
  generate_figures.R                  Figures 1-4, plus Figure 5 (membership forest plot with 90/95% CIs)
  supplementary_analysis_footnote2.R  Footnote 2 robustness check (1996 models with political ideology)
Tabs/                                 Generated LaTeX tables (booktabs + threeparttable)
Plots/                                Generated figures (PDF)
renv.lock, renv/                      R environment specification
```

## Requirements

- R 4.5 or later
- Packages are pinned in `renv.lock`. To restore the exact environment:

```r
install.packages("renv")
renv::restore()
```

## Data

All analyses use the **General Social Survey (GSS)**, 1996 and 2004 waves, obtained from NORC. The scripts fetch the data at runtime via the [`gssr`](https://github.com/kjhealy/gssr) package (`gss_get_yr()`), which downloads the official Stata files from https://gss.norc.org. No local data files are required; an internet connection is needed on the first run.

## Running the pipeline

From the repository root:

```r
source("scripts/generate_tables.R")                  # Tables 2-4 + numerical audit
source("scripts/generate_descriptives.R")            # Table 1
source("scripts/generate_figures.R")                 # Figures 1-5
source("scripts/supplementary_analysis_footnote2.R") # Footnote 2 check (writes to Supplementary/)
```

Each script sources `scripts/00_utils.R` and runs its own GSS fetch. The `Supplementary/` directory is created by the footnote 2 script and is not tracked.

## Outputs

- `Tabs/tbl-nationalism.tex`, `Tabs/tbl-regression-educ.tex`, `Tabs/tbl-regression-full-2004.tex`: regression tables (Tables 2-4)
- `Tabs/tbl-descriptives.tex`: descriptive statistics (Table 1)
- `Plots/fig-logistic-pride.pdf`: Figure 1, item-level odds ratios (2004 vs 1996)
- `Plots/fig-pride-bar.pdf`: Figure 2, distribution of the U.S. Pride scale by year
- `Plots/fig-marginal-educ.pdf`: Figure 3, predicted pride across education by year
- `Plots/fig-membership-forest-ci.pdf`: Figure 4, membership-type effects on pride with 90% and 95% intervals (swapped in for `fig-membership-forest.pdf` after acceptance, 2026-11-05)
- `Plots/fig-membership-forest.pdf`: earlier version with 95% intervals only (no longer in the manuscript)
- `Supplementary/`: footnote 2 models with political ideology (1996 only)

`generate_tables.R` prints a numerical audit that compares the statistics in the manuscript text (scale alphas, descriptive statistics, interaction and period-specific p-values, robust-to-classical SE ratios, membership-count tests) against freshly estimated models. Each line shows the pipeline value next to the value printed in the text.

## Notes on fidelity

- Regression tables (`Tabs/tbl-nationalism.tex`, `tbl-regression-educ.tex`, `tbl-regression-full-2004.tex`) and the descriptives table regenerate byte-identical to the tracked versions.
- Figures 1-5 regenerate pixel-identical to the tracked PDFs when rasterized. Byte-level PDF comparison is not meaningful because of embedded timestamps.
- The GSS Stata files are fetched from NORC at runtime. If NORC revises those files, estimates could change; the audit output will show any such change.
- Figure 1 uses `glm(family = binomial)` with survey weights as prior weights. Point estimates match survey-weighted logistic regression, but the confidence intervals do not account for the sampling design (R warns about non-integer successes). Treat these intervals as approximate.

## Citation

Lizardo, Omar. 2026. "Patriotism as a Choice Process: National Pride After 9/11." *Social Psychology Quarterly*. Accepted.

Data: Smith, T. W., et al. General Social Survey, 1996 and 2004. NORC at the University of Chicago. Accessed via the `gssr` R package (Healy 2024).
