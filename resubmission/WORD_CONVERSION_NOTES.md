# Word Document Conversion Notes

## Issue Summary

The conversion from LaTeX to Word (.docx) using pandoc encountered limitations with table rendering. **Only Table 1 (Descriptive Statistics) appears in the Word document**—Tables 2, 3, and 4 are missing from the .docx output.

### Why This Happened

Pandoc's LaTeX-to-Word conversion has known limitations when dealing with:
1. Complex table packages (`tabularray` with `talltblr` environment) 
2. Multiple tables in sequence
3. LaTeX-specific formatting commands

The original manuscript uses the modern `tabularray` package with `talltblr` tables, which pandoc struggles to convert to Word's table format.

## Current State

| Item | Status | Notes |
|------|--------|-------|
| **Text & Abstract** | ✓ Complete | All prose, citations, cross-references intact |
| **Table 1** | ✓ Rendered | Descriptive statistics table appears |
| **Table 2** | ✗ Missing | Nationalism scale predictors |
| **Table 3** | ✗ Missing | Education effects on U.S. Pride |
| **Table 4** | ✗ Missing | 2004 membership analysis |
| **Figures** | ✓ Complete | All 4 figures embedded (image descriptions in Word) |
| **Citations** | ✓ Working | In-text citations present |
| **Bibliography** | ⚠️ Needs Word processing | Citation keys present but bibliography section needs Word formatting |

## Solutions

### Option 1: Use LaTeX for Submission (Recommended)

**Most journals including *Social Psychology Quarterly* accept LaTeX submissions.**

- File: `manuscript_R1_source.tex` (in the Word folder)
- All tables render correctly
- All figures embed properly
- Ready to submit directly to the journal

**Advantage:** Perfect rendering, no manual work required

### Option 2: Manually Insert Tables in Word

If you need a .docx file:

1. Open `manuscript_R1.docx` in Microsoft Word
2. For each missing table:
   - Locate the text reference (e.g., "Table \ref{tab:nationalism}")
   - Place cursor after that sentence
   - Insert → Table → Create Table with appropriate dimensions
   - Copy table data from the source LaTeX files in `../../Tabs/`
   - Format to match Table 1 styling

Table source files:
- **Table 2:** `../../Tabs/tbl-nationalism.tex`
- **Table 3:** `../../Tabs/tbl-regression-educ.tex`
- **Table 4:** `../../Tabs/tbl-regression-full-2004.tex`

### Option 3: Use Overleaf for Conversion

Overleaf has better LaTeX-to-Word export if the journal requires it:
1. Push to Overleaf via `git push overleaf main`
2. Use Overleaf's "Download PDF" + Office conversion tools
3. Or download the PDF and use an online converter

## Bibliography Issue

The Word document has citation keys but the formatted bibliography didn't auto-generate. To fix:

1. Open Word document
2. Go to **References** → **Manage Sources**
3. Import `references.bib` if needed
4. Word will format citations automatically

Alternatively, the LaTeX version automatically generates a properly formatted bibliography.

## Recommendation

For journal submission to *Social Psychology Quarterly*, **submit the LaTeX version (`manuscript_R1_source.tex`)** rather than .docx. This ensures:
- Perfect table rendering
- All formatting preserved
- No manual work required
- Professional typesetting by the journal

The .docx version is useful only if the journal specifically requires Word format.

---

**Files in this directory:**
- `manuscript_R1.docx` — Word version (Table 1 only)
- `manuscript_R1_source.tex` — Complete LaTeX source (all tables)
- `references.bib` — Bibliography file
- `response_to_reviewers.docx` — Review response memo
- `TABLE_INSERTION_GUIDE.txt` — Instructions for manual table insertion

