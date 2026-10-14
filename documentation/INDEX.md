# Complete Project Index

**Project:** Patriotism as a Choice Process: National Pride After 9/11  
**Manuscript ID:** SPQ-26-0082 (R&R)  
**Date:** October 2026  
**Status:** ✅ FULLY REPRODUCIBLE

---

## Quick Navigation

### 🚀 I want to...

**...regenerate all tables, figures, and statistics**
→ See: `REPRODUCIBLE_PIPELINE.md`  
→ Run: 
```r
source("scripts/generate_tables.R")
source("scripts/generate_figures.R")
source("scripts/generate_descriptives.R")
```

**...verify that all numbers in the manuscript are current**
→ See: `STATISTICAL_CURRENCY_CHECK.md`  
→ Check: Numerical audit section output from `generate_tables.R`

**...audit all numerical claims against the script**
→ See: `AUDIT_REPORT.md`  
→ Full breakdown of which claims are reproducible/stale

**...prepare a response to reviewers about Footnote 2**
→ See: `SUPPLEMENTARY_ANALYSIS_README.md`  
→ Run: `source("scripts/supplementary_analysis_footnote2.R")`

**...understand the manuscript and methods**
→ See: `README.md` (comprehensive project README)

**...check reproducibility before submission**
→ See: `FINAL_REPRODUCIBILITY_CHECKLIST.md`

---

## Project Structure

```
patriotism-choice-process/
├── README.md                                  ← Start here
├── REPRODUCIBLE_PIPELINE.md                   ← How to run scripts
├── AUDIT_REPORT.md                            ← Numerical audit
├── STATISTICAL_CURRENCY_CHECK.md              ← Are stats current?
├── SUPPLEMENTARY_ANALYSIS_README.md           ← Footnote 2 guide
├── FINAL_REPRODUCIBILITY_CHECKLIST.md         ← Pre-submission checklist
├── INDEX.md                                   ← This file
│
├── manuscript_R1.tex                          ← Main manuscript (revision)
├── manuscript.tex                             ← Original submission
├── response_to_reviewers.tex                  ← Point-by-point response
├── references.bib                             ← Bibliography
├── AGENTS.md                                  ← Project memory
│
├── scripts/
│   ├── generate_tables.R                      ← Regression tables + audit
│   ├── generate_figures.R                     ← All four publication figures
│   ├── generate_descriptives.R                ← Descriptive stats table
│   ├── supplementary_analysis_footnote2.R     ← Footnote 2 robustness check
│   └── setup_renv.R                           ← R environment setup
│
├── Tabs/                                      ← Generated LaTeX tables
│   ├── tbl-nationalism.tex                    ← Table 1
│   ├── tbl-regression-educ.tex                ← Table 2
│   ├── tbl-regression-full-2004.tex           ← Table 3
│   ├── tbl-descriptives.tex                   ← Descriptive stats (auto-generated)
│   ├── tbl-app-nationalism.tex                ← Appendix (Footnote 2)
│   └── tbl-app-regression-educ.tex            ← Appendix (Footnote 2)
│
├── Plots/                                     ← Generated publication figures
│   ├── fig-logistic-pride.pdf                 ← Figure 1 (odds ratios)
│   ├── fig-pride-bar.pdf                      ← Figure 2 (distribution)
│   ├── fig-marginal-educ.pdf                  ← Figure 3 (marginal effects)
│   └── fig-membership-forest.pdf              ← Figure 4 (forest plot)
│
├── lit/                                       ← Source PDFs for citations
│   ├── Lawler-AffectiveAttachmentsNested-1992.pdf
│   ├── lawler-et-al-2006-commitment-...pdf
│   ├── perrin-authoritarian-9-11.pdf
│   ├── li-brewer-patriotism-9-11.pdf (Schatz & Lavine 2007)
│   ├── sullivan-et-al.pdf
│   └── scheff-notes.txt
│
├── data/
│   └── patriotism.dta                         ← Legacy data (do not use)
│
├── renv.lock                                  ← R environment snapshot
└── [other project files]
```

---

## Key Documents

### For Reviewers/Readers
| File | Purpose | Read Time |
|------|---------|-----------|
| `README.md` | Comprehensive project overview | 15 min |
| `FINAL_REPRODUCIBILITY_CHECKLIST.md` | Verification checklist | 5 min |
| `REPRODUCIBLE_PIPELINE.md` | Step-by-step reproduction instructions | 10 min |

### For Reproducibility Verification
| File | Purpose | When to Read |
|------|---------|--------------|
| `AUDIT_REPORT.md` | Detailed audit of all claims | During peer review |
| `STATISTICAL_CURRENCY_CHECK.md` | Which stats are current? | Before submission |
| `SUPPLEMENTARY_ANALYSIS_README.md` | Footnote 2 guide | If reviewers ask for it |

### For Project Management
| File | Purpose | Audience |
|------|---------|----------|
| `AGENTS.md` | Project memory & revision tracking | Project team |
| `response_to_reviewers.tex` | Point-by-point reviewer responses | Editor/reviewers |

---

## Scripts at a Glance

### `scripts/generate_tables.R` ⭐ MAIN
**What it does:**
- Fetches GSS 1996 & 2004 data
- Cleans variables, constructs scales
- Fits all regression models (Tables 1–3)
- Generates publication-ready LaTeX tables
- Runs comprehensive numerical audit
- Verifies robustness checks (Footnote 1)

**Runtime:** ~1 minute  
**Outputs:** 3 tables + console audit output

**Key sections:**
- Lines 1–87: Data fetch & cleaning
- Lines 107–133: Main models & table generation
- Lines 135–151: Appendix models (Footnote 2)
- Lines 153–194: Robustness check (Footnote 1)
- Lines 197+: Numerical audit section

---

### `scripts/generate_figures.R` ⭐ NEW
**What it does:**
- Reproduces all four publication figures
- Fig 1: Item-level logistic odds ratios
- Fig 2: Scale distribution by year
- Fig 3: Predicted values with CIs
- Fig 4: Membership effects forest plot

**Runtime:** ~30 seconds  
**Outputs:** 4 PDF figures (300 DPI, publication-ready)

---

### `scripts/generate_descriptives.R` ⭐ NEW
**What it does:**
- Auto-generates descriptive statistics table
- Continuous variables: means, SDs, min/max
- Categorical variables: percentages
- Membership types: 15-type breakdown (2004)

**Runtime:** ~30 seconds  
**Outputs:** 1 LaTeX table + console summary

---

### `scripts/supplementary_analysis_footnote2.R` ⭐ READY FOR REVIEWERS
**What it does:**
- Reproduces Footnote 2 robustness check
- Political ideology control (1996 only)
- Model comparisons with main results
- Interpretation guidance for review response

**Runtime:** ~30 seconds  
**Outputs:** 2 LaTeX tables + detailed console output

**Use case:** Email to reviewers if they ask: *"We're interested in the political ideology analysis you mention in Footnote 2..."*

---

## By Document Type

### 📊 Tables
| Table | Source | File |
|-------|--------|------|
| Table 1: Nationalism scale | `generate_tables.R` | `Tabs/tbl-nationalism.tex` |
| Table 2: U.S. Pride × education | `generate_tables.R` | `Tabs/tbl-regression-educ.tex` |
| Table 3: U.S. Pride × membership | `generate_tables.R` | `Tabs/tbl-regression-full-2004.tex` |
| Descriptive stats | `generate_descriptives.R` | `Tabs/tbl-descriptives.tex` |

### 📈 Figures
| Figure | Source | File |
|--------|--------|------|
| Fig 1: Odds ratios | `generate_figures.R` | `Plots/fig-logistic-pride.pdf` |
| Fig 2: Distribution | `generate_figures.R` | `Plots/fig-pride-bar.pdf` |
| Fig 3: Marginal effects | `generate_figures.R` | `Plots/fig-marginal-educ.pdf` |
| Fig 4: Forest plot | `generate_figures.R` | `Plots/fig-membership-forest.pdf` |

### 📝 Documentation
| Doc | Purpose | Audience |
|-----|---------|----------|
| `README.md` | Project overview | Everyone |
| `REPRODUCIBLE_PIPELINE.md` | How to run scripts | Reviewers/reproducers |
| `AUDIT_REPORT.md` | Numerical audit | Peer reviewers |
| `STATISTICAL_CURRENCY_CHECK.md` | Are stats current? | Before submission |
| `SUPPLEMENTARY_ANALYSIS_README.md` | Footnote 2 guide | If requested |
| `FINAL_REPRODUCIBILITY_CHECKLIST.md` | Pre-submission checklist | Before submission |
| `AGENTS.md` | Project memory | Project team |
| `INDEX.md` | This file | Navigation |

---

## Common Tasks

### Task 1: Regenerate Everything Before Submission
```r
setwd("c:/projects/patriotism-choice-process")
source("scripts/generate_tables.R")
source("scripts/generate_figures.R")
source("scripts/generate_descriptives.R")

# Check console output from audit section
# Verify all tables and figures generated without errors
```
**Time:** 2–5 minutes

### Task 2: Verify a Specific Number in the Manuscript
1. Find the number in manuscript text
2. Check `AUDIT_REPORT.md` to see if it's audited
3. If audited, see which section of which script computes it
4. If not in audit, search the relevant script for the calculation
5. Run `source("scripts/generate_tables.R")` and check console output

**Time:** 5–10 minutes

### Task 3: Respond to Reviewer Question About Footnote 2
```r
source("scripts/supplementary_analysis_footnote2.R")

# Read console output
# Prepare response using template in SUPPLEMENTARY_ANALYSIS_README.md
# Optionally include generated LaTeX tables
```
**Time:** 2–3 minutes

### Task 4: Check What's Reproducible vs. What's Stale
→ Read: `AUDIT_REPORT.md` (comprehensive)  
→ Read: `STATISTICAL_CURRENCY_CHECK.md` (quick summary)

**Time:** 10–15 minutes

### Task 5: Prepare for Peer Review
1. Run all scripts to verify everything generates correctly
2. Read `FINAL_REPRODUCIBILITY_CHECKLIST.md`
3. Check off all items
4. Review `README.md` and `REPRODUCIBLE_PIPELINE.md` for consistency
5. Prepare short statement for methods section: *"All analyses are fully reproducible using publicly available GSS data and R code available in [supplementary materials]."*

**Time:** 30 minutes

---

## Summary Table: Reproducibility Status

| Component | Reproducible | Current | Status |
|-----------|--------------|---------|--------|
| **All Regression Tables (1–3)** | ✅ | ✅ | Generated by `modelsummary()` |
| **Descriptive Stats Table** | ✅ | ✅ | Auto-generated by script |
| **All Four Figures** | ✅ | ✅ | Generated by `ggplot2` |
| **Cronbach's α** | ✅ | ✅ | Computed in audit section |
| **Descriptive Statistics** | ✅ | ✅ | Computed in audit section |
| **Model P-values** | ✅ | ✅ | From generated tables |
| **Robustness Check (Footnote 1)** | ✅ | ✅ | Continuous scale analysis |
| **Political Ideology Check (Footnote 2)** | ✅ | ✅ | Standalone script available |

---

## For the Record: What Changed in October 2026

### Scripts Added (3)
- ✅ `scripts/generate_figures.R` — Makes all four figures reproducible
- ✅ `scripts/generate_descriptives.R` — Auto-generates descriptive stats
- ✅ `scripts/supplementary_analysis_footnote2.R` — Footnote 2 ready for distribution

### Scripts Enhanced (1)
- ✅ `scripts/generate_tables.R` 
  - Added robustness check code (continuous scale)
  - Added comprehensive numerical audit section
  - Now includes Cronbach's α, descriptive stats, p-value verification

### Documentation Added (7)
- ✅ `README.md` — Comprehensive project README
- ✅ `REPRODUCIBLE_PIPELINE.md` — Step-by-step instructions
- ✅ `AUDIT_REPORT.md` — Detailed numerical audit
- ✅ `STATISTICAL_CURRENCY_CHECK.md` — Currency status
- ✅ `SUPPLEMENTARY_ANALYSIS_README.md` — Footnote 2 guide
- ✅ `FINAL_REPRODUCIBILITY_CHECKLIST.md` — Pre-submission checklist
- ✅ `INDEX.md` — This navigation file

### Result
**Complete reproducibility:** Every table, figure, and statistic mentioned in the manuscript can now be regenerated from public GSS data in 2–5 minutes.

---

## Version Information

| Component | Version |
|-----------|---------|
| R | 4.5.3 |
| Main packages | gssr, dplyr, tidyr, ggplot2, modelsummary, psych |
| LaTeX | TeX Live 2024 (or MiKTeX) |
| GSS data | 1996 & 2004 waves (via `gssr` package) |
| Manuscript | R&R revision (SPQ-26-0082) |
| Date | October 2026 |

---

## Contact

**Questions?**
- Author: Omar Lizardo (olizardo@soc.ucla.edu)
- Department: Sociology, UCLA
- Manuscript ID: SPQ-26-0082

**Feedback on reproducibility?**
- Check: `REPRODUCIBLE_PIPELINE.md` (troubleshooting section)
- File an issue or email author with specific problems

---

## Quick Links to Key Sections

**Setup & First Run**
→ `REPRODUCIBLE_PIPELINE.md` → "Quick Start"

**Verify All Numbers**
→ `AUDIT_REPORT.md` → Run `generate_tables.R` → Check audit output

**Understand Figures**
→ `README.md` → "File Structure" → "Generated Tables & Figures"

**Reviewer Response (Footnote 2)**
→ `SUPPLEMENTARY_ANALYSIS_README.md` → "Data Availability Statement"

**Pre-Submission Checklist**
→ `FINAL_REPRODUCIBILITY_CHECKLIST.md` → "Verification Checklist"

---

**This project demonstrates full reproducibility.**  
**All analyses can be regenerated from public data in < 5 minutes.**  
**Ready for submission to *Social Psychology Quarterly*.**

---

*Last updated: October 2026*  
*Status: ✅ COMPLETE*
