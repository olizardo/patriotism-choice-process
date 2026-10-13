# Complete Reproducible Pipeline

**Purpose:** This document provides step-by-step instructions to fully reproduce all tables, figures, and statistics in the manuscript from raw GSS data.

**Author:** Omar Lizardo  
**Manuscript:** Patriotism as a Choice Process: National Pride After 9/11  
**Manuscript ID:** SPQ-26-0082 (R&R)  
**Date:** October 2026

---

## Overview

The reproducible pipeline consists of **four independent R scripts**:

1. **`scripts/generate_tables.R`** — Generates regression tables and numerical audit
2. **`scripts/generate_figures.R`** — Generates all four manuscript figures
3. **`scripts/generate_descriptives.R`** — Generates descriptive statistics table
4. **`scripts/compile_manuscript.R`** — (Optional) Compiles LaTeX manuscript

All scripts use the same underlying data pipeline (GSS 1996 & 2004 via `gssr` package) and apply identical data-cleaning logic, ensuring consistency across all outputs.

---

## Prerequisites

### R & Packages
Ensure you have R 4.5+ installed with the following packages:

```r
# Install (if needed)
install.packages(c(
  "gssr",           # Access GSS data
  "dplyr",          # Data wrangling
  "tidyr",          # Reshaping
  "ggplot2",        # Visualization
  "modelsummary",   # Publication tables
  "psych",          # Scale reliability (Cronbach's α)
  "broom",          # Model tidying
  "lmtest",         # Hypothesis tests
  "sandwich"        # Robust standard errors
))

# Or restore the project environment:
renv::restore()
```

### LaTeX (Optional, for PDF compilation)
To compile the manuscript PDF locally, install a LaTeX distribution:
- **Linux:** `apt-get install texlive-science` (or `texlive-full`)
- **macOS:** [MacTeX](https://tug.org/mactex/)
- **Windows:** [MiKTeX](https://miktex.org/) or [TeX Live](https://tug.org/texlive/)

---

## Running the Pipeline

### Quick Start (Run All)
To regenerate **all tables, figures, and statistics**:

```r
# Set working directory
setwd("c:/projects/patriotism-choice-process")

# Run the three core scripts (in any order)
source("scripts/generate_tables.R")
source("scripts/generate_figures.R")
source("scripts/generate_descriptives.R")
```

This will:
- Fetch live GSS data (1996 & 2004)
- Clean and construct all variables
- Fit all regression models
- Generate publication tables (Tabs/*.tex)
- Generate all figures (Plots/*.pdf)
- Generate descriptive statistics table
- Print comprehensive numerical audit to console

**Total runtime:** ~2–5 minutes (depending on internet speed for GSS download)

### Individual Scripts

#### Script 1: Generate Regression Tables & Audit
```r
source("scripts/generate_tables.R")
```

**Outputs:**
- `Tabs/tbl-nationalism.tex` — Table 1 (Nationalism scale models)
- `Tabs/tbl-regression-educ.tex` — Table 2 (U.S. Pride × education × year)
- `Tabs/tbl-regression-full-2004.tex` — Table 3 (U.S. Pride membership effects, 2004)
- Console: Comprehensive numerical audit (Cronbach's α, descriptive stats, p-values)

**Key features:**
- Weights all models by GSS sampling weight (`wtssall`)
- Computes HC1 robust standard errors for sensitivity analysis
- Verifies robustness check results (continuous pride scale)
- Applies ASA formatting (leading zero removal, significance stars, labels)

**Runtime:** ~1 minute

---

#### Script 2: Generate Figures
```r
source("scripts/generate_figures.R")
```

**Outputs:**
- `Plots/fig-logistic-pride.pdf` — Figure 1 (Item-level odds ratios)
- `Plots/fig-pride-bar.pdf` — Figure 2 (U.S. Pride scale distribution)
- `Plots/fig-marginal-educ.pdf` — Figure 3 (Predicted values by education × year)
- `Plots/fig-membership-forest.pdf` — Figure 4 (Membership effects forest plot)

**Key features:**
- Fits item-level logistic regressions for each pride domain
- Computes predicted values with 95% confidence intervals
- Includes all 15 voluntary association membership types
- Uses consistent color scheme across figures

**Runtime:** ~30 seconds

---

#### Script 3: Generate Descriptive Statistics Table
```r
source("scripts/generate_descriptives.R")
```

**Outputs:**
- `Tabs/tbl-descriptives.tex` — Descriptive statistics table
- Console: Summary statistics for all variables

**Key features:**
- Computes means, SDs, min/max for all continuous variables
- Calculates percentages for all categorical variables
- Includes all 15 membership types breakdown (2004 wave)
- Generates ready-to-insert LaTeX code

**Runtime:** ~30 seconds

---

### Optional: Compile Manuscript
If you have LaTeX installed:

```bash
# Linux/macOS
cd c:/projects/patriotism-choice-process
pdflatex -interaction=nonstopmode manuscript_R1.tex
bibtex manuscript_R1
pdflatex -interaction=nonstopmode manuscript_R1.tex
pdflatex -interaction=nonstopmode manuscript_R1.tex

# Windows (or use TeXShop / Overleaf)
pdflatex manuscript_R1.tex
bibtex manuscript_R1.bbl
pdflatex manuscript_R1.tex
pdflatex manuscript_R1.tex
```

---

## Output Organization

### Generated Tables
```
Tabs/
├── tbl-nationalism.tex              # Table 1: Nationalism scale
├── tbl-regression-educ.tex          # Table 2: U.S. Pride education effects
├── tbl-regression-full-2004.tex     # Table 3: U.S. Pride membership effects
├── tbl-descriptives.tex             # Descriptive statistics table
├── tbl-app-nationalism.tex          # Appendix: 1996 ideology models
└── tbl-app-regression-educ.tex      # Appendix: 1996 ideology models
```

### Generated Figures
```
Plots/
├── fig-logistic-pride.pdf           # Figure 1: Item odds ratios
├── fig-pride-bar.pdf                # Figure 2: Scale distribution
├── fig-marginal-educ.pdf            # Figure 3: Marginal effects
└── fig-membership-forest.pdf        # Figure 4: Forest plot
```

All files are ready to `\input` or `\includegraphics` into the LaTeX manuscript.

---

## Data Validation Checklist

After running the full pipeline, verify:

- [ ] All four tables generated without errors
- [ ] All four figures generated as PDFs (not blank or errored)
- [ ] Console output shows:
  - Cronbach's α values (.80 and .64)
  - Descriptive statistics match manuscript Table 1
  - Key p-values match text (e.g., education × year interaction)
  - Robustness check correlation ~.87
- [ ] No warnings about missing data handling
- [ ] Sample sizes in each table match expectations
- [ ] Coefficient signs and magnitudes make theoretical sense

---

## Reproducibility Standards

This pipeline adheres to the following principles:

### 1. **Deterministic Data Fetch**
- Uses `gssr::gss_get_yr(1996)` and `gss_get_yr(2004)` to fetch live, public GSS data
- No static `.dta` or `.csv` files required
- **Caveat:** If GSS corrects historical data, results may change slightly

### 2. **Transparent Data Cleaning**
- All missing-data recoding documented in script comments
- Dichotomization logic explicitly shown
- Scale construction formula documented

### 3. **Reproducible Model Specification**
- All models explicitly defined in code
- Survey weights and listwise deletion rules specified
- Model formulas match manuscript Methods section

### 4. **Publication-Quality Output**
- Tables formatted per ASA 7th Edition standards
- Figures include confidence intervals
- All output files are final publication-ready

### 5. **Verifiable Results**
- Numerical audit section checks Cronbach's α, descriptive stats, p-values
- Robustness checks (continuous scale, HC1 SEs) included
- Correlation between alternative measures reported

---

## Customization & Troubleshooting

### Change Data Source
To use a different dataset instead of GSS, modify the data fetch in each script:

```r
# Instead of:
gss96 <- gss_get_yr(1996)
gss04 <- gss_get_yr(2004)

# Use your own data:
gss96 <- read.csv("my_data_1996.csv")
gss04 <- read.csv("my_data_2004.csv")
```

Then ensure variable names match the cleaning pipeline.

### Modify Model Specification
To change which variables are included, edit the `lm()` or `glm()` formulas in each script.

Example: Remove `cohort` from a model:
```r
# Old:
mod <- lm(uspridescal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)

# New:
mod <- lm(uspridescal ~ educ * year_f, data = gss_clean, weights = wtssall)
```

### Figure Customization
To adjust figure aesthetics:
- Colors: Modify `scale_color_manual()` and `scale_fill_manual()` calls
- Size/resolution: Change `width`, `height`, `dpi` in `ggsave()` calls
- Themes: Replace `theme_minimal()` with `theme_classic()` or others

---

## Expected Output Quality

### Tables
- All coefficients and SEs match 4 decimal places
- P-values match to 3 decimal places
- Sample sizes and model fit statistics included
- Significance stars (*, **, ***) applied correctly

### Figures
- High-resolution PDFs (300 DPI)
- Clear legends and axis labels
- Confidence intervals/CIs clearly visible
- Color-blind friendly palette

---

## File Dependencies

```
generate_tables.R
  └─ requires: gssr, dplyr, tidyr, modelsummary, psych, sandwich, lmtest
  └─ outputs: Tabs/tbl-*.tex

generate_figures.R
  └─ requires: gssr, dplyr, tidyr, ggplot2, broom
  └─ outputs: Plots/fig-*.pdf

generate_descriptives.R
  └─ requires: gssr, dplyr, tidyr, knitr
  └─ outputs: Tabs/tbl-descriptives.tex

manuscript_R1.tex
  └─ inputs: Tabs/tbl-*.tex, Plots/fig-*.pdf
  └─ outputs: manuscript_R1.pdf (when compiled)
```

---

## Session Info

The scripts were written and tested on:

- **R version:** 4.5.3
- **Platform:** Windows 10 / macOS / Linux
- **Key packages:**
  - gssr (GSS data access)
  - dplyr (≥ 1.0.0 for across/if_all functions)
  - ggplot2 (≥ 3.3.0)
  - modelsummary (≥ 1.0.0)
  - psych (for Cronbach's α)
  - sandwich (for HC1 robust SEs)

---

## Contact & Issues

For questions or to report issues with reproducibility:

- **Author:** Omar Lizardo (olizardo@soc.ucla.edu)
- **Manuscript ID:** SPQ-26-0082
- **Revision Status:** R&R (Revise and Resubmit)

---

## Change Log

### October 2026 (Current Version)
- ✅ Added `generate_figures.R` to reproduce all four figures
- ✅ Added `generate_descriptives.R` to auto-generate descriptive statistics table
- ✅ Added robustness check code to `generate_tables.R` (continuous pride scale)
- ✅ Added comprehensive numerical audit section to `generate_tables.R`
- ✅ Created this reproducible pipeline documentation

### September 2026 (Original Submission)
- Initial submission to *Social Psychology Quarterly*
- Tables generated via `modelsummary()`
- Figures created ad-hoc without reproducible pipeline

---

## License

[Specify appropriate license — e.g., MIT, CC-BY-4.0]

---

## Citation

If you use this pipeline to reproduce or adapt these analyses, please cite:

> Lizardo, O. (2026). Patriotism as a Choice Process: National Pride After 9/11. 
> *Social Psychology Quarterly*, [Volume(Issue)], [Pages]. 
> Manuscript ID SPQ-26-0082.
> 
> Code available at: [GitHub repository link]

