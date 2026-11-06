# Build the Word (docx) version of the manuscript tables and figures.
# Parses the booktabs tables straight from the LaTeX sources so the numbers
# match the accepted manuscript exactly, renders them as flextables, and
# appends Tables + Figures sections to the pandoc-produced docx.

library(flextable)
library(officer)

proj <- "/home/omarlizardo/projects/SOCIAL PSYCH/patriotism-choice-process"
docx_path <- file.path(proj, "word_port", "manuscript_final.docx")
png_dir <- file.path(proj, "word_port", "figures_png")

# ---- extract the tabular body, caption, and note from a table source
parse_table <- function(src) {
  tab <- regmatches(src, regexpr("(?s)\\\\begin\\{tabular\\}\\{[^}]*\\}.*?\\\\end\\{tabular\\}", src, perl = TRUE))
  body <- sub("^\\\\begin\\{tabular\\}\\{[^}]*\\}", "", tab)
  body <- sub("\\\\end\\{tabular\\}$", "", body)
  body <- sub(".*?\\\\toprule", "", body)
  body <- sub("\\\\bottomrule.*$", "", body)

  cap <- regmatches(src, regexpr("(?s)\\\\caption\\{.*?\\}", src, perl = TRUE))
  cap <- if (length(cap)) sub("^\\\\caption\\{", "", sub("\\}$", "", cap)) else ""
  cap <- gsub("`([^']*)'", "\u201c\\1\u201d", cap)

  note <- regmatches(src, regexpr("(?s)\\\\item Note:(.*?)\\\\end\\{tablenotes\\}", src, perl = TRUE))
  note <- if (length(note)) sub("\\\\end\\{tablenotes\\}$", "", sub("^\\\\item ", "", note)) else ""
  note <- trimws(gsub("\\$", "", note))

  rows_raw <- strsplit(body, "\\\\\\\\")[[1]]
  rows_raw <- trimws(rows_raw)
  rows_raw <- rows_raw[nzchar(rows_raw)]

  cells_list <- list()
  for (r in rows_raw) {
    if (grepl("\\\\(mid)?rule", r)) {
      cells_list[[length(cells_list) + 1]] <- "RULE"
    } else {
      cells <- trimws(strsplit(r, "&")[[1]])
      cells <- vapply(cells, function(x) {
        x <- gsub("\\\\textbf\\{([^}]*)\\}", "\\1", x)
        x <- gsub("\\\\%", "%", x)
        x <- gsub("\\$([^$]*)\\$", "\\1", x)
        x <- gsub("~", " ", x)
        x <- gsub("\\\\,", " ", x)
        trimws(x)
      }, character(1))
      cells_list[[length(cells_list) + 1]] <- cells
    }
  }

  header <- cells_list[[1]]
  ncol <- length(header)
  mat <- character(0)
  for (cells in cells_list[-1]) {
    if (identical(cells, "RULE")) {
      mat <- rbind(mat, rep("", ncol))
    } else {
      cells <- c(cells, rep("", ncol - length(cells)))[seq_len(ncol)]
      mat <- rbind(mat, cells)
    }
  }
  df <- as.data.frame(mat, stringsAsFactors = FALSE)
  names(df) <- ifelse(nzchar(header), header, " ")
  list(df = df, caption = cap, note = note)
}

# ---- booktabs-styled flextable, sized to full text-column width
make_ft <- function(df, total_width = 6.0) {
  ft <- flextable(df)
  ft <- fontsize(ft, size = 10, part = "all")
  ft <- bold(ft, part = "header")
  ft <- border_remove(ft)
  std <- officer::fp_border(width = 1)
  heavy <- officer::fp_border(width = 2)
  ft <- border(ft, border.top = heavy, part = "header")
  ft <- border(ft, border.bottom = std, part = "header")
  ft <- border(ft, border.bottom = heavy, part = "body", i = nrow_part(ft, "body"))
  ft <- align(ft, j = 1, align = "left", part = "all")
  if (ncol(df) > 1) ft <- align(ft, j = 2:ncol(df), align = "center", part = "all")
  ft <- valign(ft, valign = "top", part = "all")
  ft <- padding(ft, padding = 3, part = "all")
  # first column wide enough for the longest variable label, remaining
  # columns share the rest of the 6.0" text width (letter, 1.25" margins)
  w1 <- min(2.8, max(nchar(c(names(df)[1], df[[1]]))) * 0.082 + 0.2)
  ft <- width(ft, j = 1, width = w1)
  if (ncol(df) > 1) {
    w_rest <- (total_width - w1) / (ncol(df) - 1)
    for (j in 2:ncol(df)) ft <- width(ft, j = j, width = w_rest)
  }
  ft <- set_table_properties(ft, layout = "fixed")
  ft
}
nrow_part <- function(ft, part) nrow(ft$body$dataset)

add_caption <- function(doc, text) {
  doc <- body_add_fpar(doc, fpar(ftext(text, prop = fp_text(bold = TRUE, font.size = 11)),
                                 fp_p = fp_par(padding.bottom = 6)))
  doc
}
add_note <- function(doc, note) {
  if (!nzchar(note)) return(doc)
  body_add_fpar(doc, fpar(ftext(note, prop = fp_text(italic = TRUE, font.size = 9)),
                          fp_p = fp_par(padding.top = 4)))
}

# ---- load the four table sources (order = manuscript order)
man <- readLines(file.path(proj, "manuscript_final.tex"), warn = FALSE)
inline_tbl <- paste(man, collapse = "\n")
inline_tbl <- regmatches(inline_tbl, regexpr("(?s)\\\\begin\\{table\\}.*?\\\\end\\{table\\}", inline_tbl, perl = TRUE))

sources <- list(
  inline_tbl,
  paste(readLines(file.path(proj, "Tabs", "tbl-nationalism.tex"), warn = FALSE), collapse = "\n"),
  paste(readLines(file.path(proj, "Tabs", "tbl-regression-educ.tex"), warn = FALSE), collapse = "\n"),
  paste(readLines(file.path(proj, "Tabs", "tbl-regression-full-2004.tex"), warn = FALSE), collapse = "\n")
)
tables <- lapply(sources, parse_table)
for (i in seq_along(tables)) {
  cat(sprintf("Table %d: %d rows x %d cols | %s\n", i, nrow(tables[[i]]$df), ncol(tables[[i]]$df), tables[[i]]$caption))
}

# ---- figures: file, caption, target width in inches
figures <- list(
  list(f = "fig-logistic-pride.png",     w = 6.5, cap = "Increase in Likelihood of Being \u201cVery Proud\u201d Post-9/11 (Odds Ratios)"),
  list(f = "fig-pride-bar.png",          w = 5.2, cap = "Distribution of U.S. Pride Scale Scores (1996 vs. 2004)"),
  list(f = "fig-marginal-educ.png",      w = 5.2, cap = "Predicted U.S. Pride Score across Education Levels by Year"),
  list(f = "fig-membership-forest-ci.png", w = 6.5, cap = "Effect of Specific Association Memberships on U.S. Pride (Controlling for Birth Cohort, Sex, Race, and Region)")
)

png_dims <- function(path) {
  raw <- readBin(path, "raw", n = 33)
  w <- readBin(raw[17:20], "integer", size = 4, endian = "big")
  h <- readBin(raw[21:24], "integer", size = 4, endian = "big")
  c(w = w, h = h)
}

# ---- assemble
doc <- read_docx(docx_path)

# match the manuscript's page setup: US letter, 1.25" margins
doc <- body_set_default_section(
  doc,
  prop_section(
    page_size = page_size(width = 8.5, height = 11, orient = "portrait"),
    page_margins = page_mar(bottom = 1.25, top = 1.25, left = 1.25, right = 1.25)
  )
)

doc <- body_add_fpar(doc, fpar(ftext("Tables", prop = fp_text(bold = TRUE, font.size = 14))))
for (i in seq_along(tables)) {
  tb <- tables[[i]]
  doc <- body_add_break(doc)
  doc <- add_caption(doc, sprintf("Table %d. %s", i, tb$caption))
  doc <- body_add_flextable(doc, make_ft(tb$df))
  doc <- add_note(doc, tb$note)
}

doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("Figures", prop = fp_text(bold = TRUE, font.size = 14))))
for (i in seq_along(figures)) {
  fg <- figures[[i]]
  if (i > 1) doc <- body_add_break(doc)
  path <- file.path(png_dir, fg$f)
  d <- png_dims(path)
  w <- min(fg$w, d[["w"]] / 300)
  doc <- add_caption(doc, sprintf("Figure %d. %s", i, fg$cap))
  doc <- body_add_img(doc, src = path, width = w, height = w * d[["h"]] / d[["w"]])
}

print(doc, target = docx_path)
cat("written:", docx_path, "\n")
