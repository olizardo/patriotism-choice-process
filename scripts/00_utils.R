# Shared helpers for the replication pipeline.
# Sourced at the top of every analysis script.

# String concatenation operator used throughout the pipeline scripts
`%+%` <- paste0

# modelsummary: write plain numbers (no \num{}) so tables compile without
# siunitx, per the ScholarOne/production requirements for this manuscript.
options("modelsummary_format_numeric_latex" = "plain")

# Significance legend used in all regression table notes
asa_significance_note <- "Note: + $p < .1$, * $p < .05$, ** $p < .01$, *** $p < .001$"

# Convert a modelsummary LaTeX table (tinytable engine) into the plain
# booktabs + threeparttable format used in the manuscript. Extracts the
# header and data rows (the only lines containing "&"), drops the automatic
# model-number row ("(1) (2) ..."), applies ASA-style leading-zero
# suppression, and wraps everything in the standard table skeleton.
convert_to_booktabs <- function(tex_file, caption, label, note = asa_significance_note) {
  lines <- readLines(tex_file)

  body <- grep("&", lines, value = TRUE)
  body <- trimws(body)
  body <- paste0(trimws(gsub("\\\\", "", body)), " \\\\")  # normalize single space before trailing \\

  # Drop the automatic model-number header row, e.g. " & (1) & (2)"
  is_model_number_row <- vapply(body, function(ln) {
    cells <- trimws(strsplit(ln, "&", fixed = TRUE)[[1]])
    nonempty <- cells[nzchar(cells)]
    length(nonempty) > 0 && all(grepl("^\\([0-9]+\\)$", nonempty))
  }, logical(1))
  body <- body[!is_model_number_row]

  # ASA style: omit leading zeros on numbers that cannot exceed 1 in magnitude
  body <- gsub("(?<![0-9.])(-?)0\\.([0-9]*[1-9][0-9]*)", "\\1.\\2", body, perl = TRUE)

  # Column layout: term column left-aligned, model columns right-aligned
  n_cols <- max(lengths(strsplit(body, "&", fixed = TRUE)))
  colspec <- paste0("l", strrep("r", n_cols - 1))

  out <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\begin{threeparttable}",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    "\\small",
    paste0("\\begin{tabular}{", colspec, "}"),
    "\\toprule",
    body[1],
    "\\midrule",
    body[-1],
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}",
    "\\small",
    paste0("\\item ", note),
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )
  invisible(out)
}

# Write a modelsummary table to disk in the manuscript's booktabs format:
# modelsummary renders to a temporary file, then convert_to_booktabs()
# rewrites it. `...` passes arguments through to modelsummary().
write_table_booktabs <- function(path, caption, label, ...) {
  tmp <- tempfile(fileext = ".tex")
  modelsummary::modelsummary(..., output = tmp, gof_omit = "^F$")
  tex <- convert_to_booktabs(tmp, caption, label)
  writeLines(tex, path)
  cat("  ✓ Saved:", path, "\n")
}
