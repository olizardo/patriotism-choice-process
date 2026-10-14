# Project Memory: patriotism-choice-process

## Overview
Manuscript project: *Patriotism as a Choice Process: National Pride After 9/11* (Omar Lizardo, UCLA). Currently under revise-and-resubmit at *Social Psychology Quarterly* (Manuscript ID SPQ-26-0082, decision received 2026-09-29).

## Status (October 2026, Final Update)

### ✅ MANUSCRIPT READY FOR RESUBMISSION

All revisions addressed per reviewer feedback. Submission package prepared for ScholarOne upload.

**Latest Session (October 13, 2026):**
- Converted all tables from `tabularray` to standard `booktabs` format for ScholarOne compatibility
- Fixed table notes with proper significance legend formatting
- Embedded bibliography directly in manuscript (no external .bib compilation needed)
- Removed all `siunitx` package dependencies
- Updated Tabs/*.tex files with production-ready LaTeX
- Verified compilation with pdflatex locally
- Ready for re-upload to ScholarOne

## Key Files

### Submission Package
- Location: `submission_package/`
- Contents:
  - `manuscript_R1.tex` — Main manuscript with embedded bibliography
  - `references.bib` — Bibliography (44 citations)
  - `Tabs/tbl-*.tex` — 3 regression tables (booktabs format)
  - `Plots/fig-*.pdf` — 4 main figures
  - `response_to_reviewers.pdf` — Point-by-point reviewer response
  - `README.txt` — Upload instructions

- Production Status: ✅ READY FOR SCHOLARONE

### Main Manuscript Files
- `resubmission/LaTeX/manuscript_R1.tex` — Original source
- `resubmission/LaTeX/response_to_reviewers.tex` — Reviewer response source
- `resubmission/Word/` — Word versions (for reference only; LaTeX is canonical)

## Reproducible Scripts
All analyses reproducible via R scripts in `scripts/`:
- `generate_tables.R` — Regression tables (uses gssr for GSS data)
- `generate_figures.R` — All 4 publication figures
- `generate_descriptives.R` — Descriptive statistics
- `supplementary_analysis_footnote2.R` — Political ideology robustness check

## Technical Details

### Table Conversion (October 2026)
**Problem:** Original tables used `tabularray` package with `talltblr` environment, which ScholarOne couldn't compile.

**Solution:** 
- Converted all tables to standard LaTeX `booktabs` + `threeparttable` format
- Removed `\num{}` formatting (replaced with plain numbers)
- Fixed table notes with proper math-mode `<` characters: `Note: + $p < .1$, * $p < .05$, ** $p < .01$, *** $p < .001$`
- Added `\begin{threeparttable}...\end{threeparttable}` wrapper for table notes

**Files Updated:**
- `Tabs/tbl-nationalism.tex`
- `Tabs/tbl-regression-educ.tex`
- `Tabs/tbl-regression-full-2004.tex`

### Bibliography Embedding
- Originally referenced via `\bibliography{references}` 
- Now: Full `.bbl` content embedded directly in manuscript
- Reason: ScholarOne may not run bibtex separately; embedding ensures bibliography renders

### Package Dependencies (Final)
Required packages:
- `geometry` (margins)
- `authblk` (author affiliations)
- `graphicx` (figures)
- `booktabs` (tables)
- `threeparttable` (table notes)
- `float`, `ulem`, `hyperref`, `setspace`, `natbib`

Removed:
- `tabularray` (complex table environment)
- `siunitx` (number formatting)

## Revision History

### Reviewer Feedback Addressed (R&R SPQ-26-0082)

**Editors (3 points):**
1. ✅ Theoretical mechanisms underdeveloped → Added Lawler frameworks, Sec. 3.2.1 on outcome distinction
2. ✅ Presentation/flow needs polish → Comprehensive prose revision throughout
3. ✅ Methods section missing → Added Sec. 3.5 Analytic Strategy + robustness checks

**Reviewer 1 (5 points):**
1. ✅ Theoretical substance → Grounded in Lawler (1992), added Lawler et al. (2006)
2. ✅ No 9/11 context → Added Sec. 2.3 opening with Perrin, Schatz & Lavine, Sullivan et al.
3. ✅ Confounding events (9/11 vs Iraq War) → Reframed as post-9/11 period with explicit limitation
4. ✅ Methods details → New Analytic Strategy section
5. ✅ "Excessive" attachment → Removed, reframed as blind patriotism per Schatz, Staub, & Lavine

**Reviewer 2 (4 points):**
1. ✅ SIT/needs-based link → Moved footnote to main text, reframed around self-esteem motive
2. ✅ Proximal/distal intro → Moved to Introduction
3. ✅ Prose rewrite → Comprehensive revision for flow and clarity
4. ✅ Supplementary tables → Appendix A deleted, results in footnote (available upon request)

## Reproducibility

### Data Pipeline
```r
source("scripts/generate_tables.R")      # Regenerates Tables 1-3 + audit
source("scripts/generate_figures.R")     # Regenerates all 4 figures
source("scripts/generate_descriptives.R") # Regenerates descriptive stats
source("scripts/supplementary_analysis_footnote2.R") # Political ideology check
```

All scripts:
- Fetch live GSS data via `gssr::gss_get_yr()`
- Use identical data cleaning pipeline
- Generate publication-ready outputs
- Runtime: 2-5 minutes total

### Numerical Audit
See `documentation/AUDIT_REPORT.md` for:
- Cronbach's α values
- Descriptive statistics verification
- Model coefficients spot-checked against tables
- All p-values verified

## Submission Status

### ScholarOne Submission (SPQ-26-0082, R&R)
- **Step 2:** Title, Abstract ✅
- **Step 3:** File Upload ✅ (ready for fresh upload of corrected package)
- **Step 4-6:** Pending

### For Next Upload
1. Delete current files from ScholarOne Step 3
2. Upload fresh `submission_package/` contents:
   - `manuscript_R1.tex` (Main Document)
   - `references.bib`, `Tabs/*.tex`, `Plots/*.pdf` (TeX/LaTeX Suppl Files)
   - `response_to_reviewers.pdf` (Supplementary Review Files)
3. ScholarOne will auto-compile and generate proof

### Expected Rendering
- ✅ All text, citations, cross-references
- ✅ Bibliography (embedded)
- ✅ All 4 figures
- ✅ Table 1 (descriptive) + Tables 2-4 (regression)
- ✅ Table notes with significance legend

## Documentation Files
- `README.md` — Project overview
- `REPRODUCIBLE_PIPELINE.md` — How to regenerate everything
- `AUDIT_REPORT.md` — Numerical verification
- `STATISTICAL_CURRENCY_CHECK.md` — Which statistics are current
- `SUPPLEMENTARY_ANALYSIS_README.md` — Footnote 2 analysis
- `FINAL_REPRODUCIBILITY_CHECKLIST.md` — Pre-submission checklist
- `INDEX.md` — Navigation guide

## Contact
- **Author:** Omar Lizardo
- **Email:** olizardo@soc.ucla.edu
- **Institution:** UCLA Department of Sociology
- **Manuscript ID:** SPQ-26-0082
- **Journal:** Social Psychology Quarterly

## Git Status
- **Local branch:** main
- **Remote:** origin/main (GitHub), overleaf/main (Overleaf)
- **Last commit:** (to be updated with this session's changes)

---

**RECOMMENDATION:** Manuscript is production-ready for submission. All technical issues resolved. Ready for ScholarOne re-upload.

