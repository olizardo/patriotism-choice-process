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

# Shared GSS data-cleaning pipeline. All three analysis scripts source this
# instead of carrying their own copies of the cleaning block. Two steps were
# deliberately different between the accepted-R1 scripts, so they are
# parameterized to preserve each script's published behavior exactly:
#
#   pride_filter:
#     "all_missing" — drop rows where ALL pride items are NA (listwise
#                     deletion at scale level); used by the regression/
#                     figure scripts.
#     "any_zero"    — drop rows where ANY pride item carries the invalid
#                     code 0; used by the descriptives script (Table 1).
#   memnum_dk_as_zero: if TRUE, recode DK/refused (98/99) memberships to 0
#                     (descriptives denominator); if FALSE, recode to NA
#                     (regression scripts).
#
# Data loading and variable selection stay in the calling scripts.
gss_clean_data <- function(gss_comb,
                           pride_filter = c("all_missing", "any_zero"),
                           memnum_dk_as_zero = FALSE) {
  pride_filter <- match.arg(pride_filter)

  out <- gss_comb %>%
    mutate(across(everything(), as.numeric))

  if (pride_filter == "all_missing") {
    out <- out %>% filter(!if_all(prouddem:proudgrp, ~ is.na(.x)))
  } else {
    # Drop rows where any pride item carries the invalid code 0
    out <- out %>% filter(if_all(prouddem:proudgrp, ~ .x != 0 | is.na(.x)))
  }

  out <- out %>%
    mutate(
      # Set ambornin:amsports missing codes (0, 9) to NA
      across(ambornin:amsports, ~ na_if(.x, 0)),
      across(ambornin:amsports, ~ na_if(.x, 9)),
      # Dichotomize pride items: 1 = "very proud", 0 = all other responses
      across(prouddem:proudgrp, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
      # Dichotomize patriotism items: 1 if response is 1, 0 otherwise
      across(ambornin:amfeel, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
      # Nationalism items: keep on 1-5 Likert scale, map code 8 to 3 (ambiguous code handling)
      across(c(amcitizn, amshamed, belikeus, ambetter, ifwrong), ~ ifelse(.x == 8, 3, .x)),
      educ = ifelse(educ %in% c(98, 99), NA, educ),
      degree = ifelse(degree %in% c(8, 9), NA, degree),
      # -1 is missing; 98/99 (DK/refused) as NA or 0 memberships per argument
      memnum = ifelse(memnum == -1, NA,
                      ifelse(memnum %in% c(98, 99),
                             if (memnum_dk_as_zero) 0 else NA,
                             memnum)),
      usaborn = ifelse(born == 1, 1, 0),
      south = ifelse(region == 3, 1, 0),
      conservative = ifelse(is.na(polviews), NA, ifelse(polviews %in% c(6, 7), 1, 0)),
      memnumcat = case_when(
        memnum == 0 ~ "0",
        memnum %in% 1:2 ~ "1-2",
        memnum >= 3 ~ "3+",
        TRUE ~ NA_character_
      ),
      memnumcat = factor(memnumcat, levels = c("0", "1-2", "3+")),
      cohort = year - age
    ) %>%
    mutate(across(memfrat:memchurh, ~ ifelse(.x > 0 & !is.na(.x) & .x == 1, 1, 0), .names = "{.col}bin")) %>%
    rowwise() %>%
    mutate(
      # U.S. Pride Scale: sum of dichotomized items (0-10), counts "very proud" responses
      uspridescal = if(any(is.na(c_across(prouddembin:proudgrpbin)))) NA_real_
                    else sum(c_across(prouddembin:proudgrpbin)),
      # U.S. Pride Scale (continuous): mean of un-dichotomized pride items,
      # reverse-coded (5 - x) so higher values = more pride (raw 1 = very proud)
      uspridescal_continuous = if(any(is.na(c_across(prouddem:proudgrp)))) NA_real_
                                else 5 - mean(c_across(prouddem:proudgrp), na.rm = TRUE),
      # Nationalism Scale: mean of 4 reverse-coded items on 1-5 Likert scale
      # (6 - mean() reverses so higher values = stronger nationalism)
      nationalistscal = 6 - mean(c_across(c(amcitizn, belikeus, ambetter, ifwrong)), na.rm = TRUE)
    ) %>%
    ungroup() %>%
    filter(!is.na(wtssall)) %>%
    mutate(
      year_f = factor(year),
      sex_f = factor(sex),
      race_f = factor(race)
    )
  out
}

# Load and combine the 1996/2004 GSS extracts, keeping the analysis variables.
# Any of vars_to_keep missing from an extract is silently skipped (any_of()).
gss_load_comb <- function() {
  gss_comb <- bind_rows(gss_get_yr(1996), gss_get_yr(2004)) %>%
    select(
      any_of(c("year", "age", "educ", "degree", "sex", "race", "polviews",
               "born", "reg16", "region", "sei", "wtssall", "belikeus", "ifwrong")),
      starts_with("proud"),
      starts_with("am"),
      starts_with("mem")
    ) %>%
    filter(year %in% c(1996, 2004))
  gss_comb
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
