# Replication Package: *Patriotism as a Choice Process: National Pride After 9/11*

Omar Lizardo (UCLA). Forthcoming in *Social Psychology Quarterly* (Manuscript ID SPQ-26-0082).

This repository contains the data-analysis pipeline that generates all numerical results, tables, and figures in the paper.

## Contents

```
scripts/
  00_utils.R                          Shared helpers (table formatting, modelsummary options)
  generate_tables.R                   Tables 2-4 (regression tables, booktabs LaTeX)
  generate_descriptives.R             Table 1 (descriptive statistics)
  generate_figures.R                  Figures 1-4
  supplementary_analysis_footnote2.R  Footnote 2 robustness check (political ideology)
Tabs/                                 Generated LaTeX tables
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

All analyses use the **General Social Survey (GSS)**, 1996 and 2004 waves, obtained from
NORC. The scripts fetch the data directly from NORC at runtime via the
[`gssr`](https://github.com/kjhealy/gssr) package (`gss_get_yr()`), which downloads the
official Stata files from https://gss.norc.org. No local data files are required; an
internet connection is needed on first run.

## Running the pipeline

From the repository root:

```r
source("scripts/generate_tables.R")                  # Tables 2-4 + numerical audit
source("scripts/generate_descriptives.R")            # Table 1 (descriptives)
source("scripts/generate_figures.R")                 # Figures 1-4
source("scripts/supplementary_analysis_footnote2.R") # Footnote 2 check (optional)
```

Approximate runtime: 5-10 minutes total (dominated by the GSS downloads, which are
cached after the first fetch within a session).

## Outputs

- `Tabs/tbl-nationalism.tex`, `Tabs/tbl-regression-educ.tex`,
  `Tabs/tbl-regression-full-2004.tex` — regression tables in the manuscript
  (booktabs + threeparttable format)
- `Tabs/tbl-descriptives.tex` — descriptive statistics (Table 1)
- `Plots/fig-logistic-pride.pdf` — Figure 1: item-level odds ratios (2004 vs 1996)
- `Plots/fig-pride-bar.pdf` — Figure 2: distribution of the U.S. Pride scale by year
- `Plots/fig-marginal-educ.pdf` — Figure 3: predicted pride across education by year
- `Plots/fig-membership-forest.pdf` — Figure 4: membership-type effects on pride

`generate_tables.R` also prints a numerical audit verifying the statistics reported in
the text (Cronbach's alpha, interaction p-values, robust/classical SE ratios).

## Notes on fidelity

- Regression tables regenerate **byte-identical** to the accepted manuscript versions.
- Descriptive statistics reproduce the manuscript's Table 1 exactly, except two
  membership percentages that differ by 0.1 percentage points at a rounding boundary
  (Church-affiliated, Hobby); these derive from the original Stata pipeline's marginally
  different sample denominator.
- Figures regenerate with identical content. Minor cosmetic differences (ordering of
  adjacent items with near-equal estimates) can arise because NORC occasionally updates
  the underlying GSS Stata files between releases.

## Citation

Lizardo, Omar. 2026. "Patriotism as a Choice Process: National Pride After 9/11."
*Social Psychology Quarterly*. Forthcoming.

Data: Smith, T. W., et al. General Social Survey, 1996 and 2004. NORC at the
University of Chicago. Accessed via the `gssr` R package (Healy 2024).
