library(gssr)
library(dplyr)
library(tidyr)
library(knitr)

# ============================================================================
# GENERATE DESCRIPTIVE STATISTICS TABLE
# ============================================================================
# This script generates the descriptive statistics table for the manuscript
# Output: Tabs/tbl-descriptives.tex (LaTeX table)
# ============================================================================

# Load and clean data (same as generate_tables.R)
gss96 <- gss_get_yr(1996)
gss04 <- gss_get_yr(2004)

vars_to_keep <- c("year", "age", "educ", "degree", "sex", "race", "polviews", "born", 
                  "reg16", "region", "sei", "wtssall", "belikeus", "ifwrong")

gss_comb <- bind_rows(gss96, gss04) %>%
  select(any_of(vars_to_keep), 
         starts_with("proud"), 
         starts_with("am"), 
         starts_with("mem")) %>%
  filter(year %in% c(1996, 2004))

gss_clean <- gss_comb %>%
  mutate(across(everything(), as.numeric)) %>%
  filter(!if_all(prouddem:proudgrp, ~ is.na(.x))) %>%
  mutate(
    across(ambornin:amsports, ~ na_if(.x, 0)),
    across(ambornin:amsports, ~ na_if(.x, 9)),
    across(prouddem:proudgrp, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
    across(ambornin:amfeel, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
    across(c(amcitizn, amshamed, belikeus, ambetter, ifwrong), ~ ifelse(.x == 8, 3, .x)),
    educ = ifelse(educ %in% c(98, 99), NA, educ),
    degree = ifelse(degree %in% c(8, 9), NA, degree),
    memnum = ifelse(memnum == -1, NA, ifelse(memnum %in% c(98, 99), NA, memnum)),
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
    uspridescal = if(any(is.na(c_across(prouddembin:proudgrpbin)))) NA_real_ 
                  else sum(c_across(prouddembin:proudgrpbin)),
    nationalistscal = 6 - mean(c_across(c(amcitizn, belikeus, ambetter, ifwrong)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(!is.na(wtssall)) %>%
  mutate(
    year_f = factor(year),
    sex_f = factor(sex),
    race_f = factor(race)
  )

cat("Data loaded and cleaned. Computing descriptive statistics...\n\n")

# ============================================================================
# COMPUTE DESCRIPTIVE STATISTICS
# ============================================================================

# Continuous variables
desc_continuous <- gss_clean %>%
  summarise(
    `U.S. Pride Scale` = list(c(mean = mean(uspridescal, na.rm = TRUE), 
                                 sd = sd(uspridescal, na.rm = TRUE),
                                 min = min(uspridescal, na.rm = TRUE),
                                 max = max(uspridescal, na.rm = TRUE))),
    `Nationalism Scale` = list(c(mean = mean(nationalistscal, na.rm = TRUE),
                                  sd = sd(nationalistscal, na.rm = TRUE),
                                  min = min(nationalistscal, na.rm = TRUE),
                                  max = max(nationalistscal, na.rm = TRUE))),
    `Education (Years)` = list(c(mean = mean(educ, na.rm = TRUE),
                                  sd = sd(educ, na.rm = TRUE),
                                  min = min(educ, na.rm = TRUE),
                                  max = max(educ, na.rm = TRUE))),
    `Birth Cohort` = list(c(mean = mean(cohort, na.rm = TRUE),
                             sd = sd(cohort, na.rm = TRUE),
                             min = min(cohort, na.rm = TRUE),
                             max = max(cohort, na.rm = TRUE))),
    `Total Memberships` = list(c(mean = mean(memnum, na.rm = TRUE),
                                  sd = sd(memnum, na.rm = TRUE),
                                  min = min(memnum, na.rm = TRUE),
                                  max = max(memnum, na.rm = TRUE)))
  ) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "stats") %>%
  unnest_wider(stats) %>%
  mutate(
    mean = round(mean, 2),
    sd = round(sd, 2),
    min = round(min, 0),
    max = round(max, 0)
  )

# Categorical variables
desc_categorical <- tibble(
  variable = c("Female", "Race: White", "Race: Black", "Race: Other", 
               "Region: South", "Political Ideology: Conservative"),
  pct_yes = c(
    mean(gss_clean$sex_f == 2, na.rm = TRUE) * 100,
    mean(gss_clean$race == 1, na.rm = TRUE) * 100,
    mean(gss_clean$race == 2, na.rm = TRUE) * 100,
    mean(gss_clean$race == 3, na.rm = TRUE) * 100,
    mean(gss_clean$south == 1, na.rm = TRUE) * 100,
    mean(gss_clean$conservative == 1, na.rm = TRUE) * 100
  )
) %>%
  mutate(pct_yes = round(pct_yes, 1))

# Membership types
desc_memberships <- tibble(
  membership_type = c(
    "Church-affiliated", "Sports", "Professional", "School", "Hobby",
    "Literary or Art", "Youth", "Labor Union", "Service", "Fraternal",
    "Veterans", "Political", "School Fraternity/Sorority", "Farm", "Nationality"
  ),
  pct_member = c(
    mean(gss_2004$memchurchbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memsportsbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memprofbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memschoolbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memhobbyin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memlitbookbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memyouthbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memlaborbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memservbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memfraterbinorg == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memveteransbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$mempoliticalbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memfratbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memfarmbin == 1, na.rm = TRUE) * 100,
    mean(gss_2004$memnationalitybin == 1, na.rm = TRUE) * 100
  )
) %>%
  mutate(pct_member = round(pct_member, 1))

# Filter 2004 for membership-specific stats
gss_2004 <- gss_clean %>% filter(year == 2004)

# ============================================================================
# PRINT SUMMARY STATISTICS
# ============================================================================

cat("CONTINUOUS VARIABLES:\n")
print(desc_continuous)
cat("\n\nCATEGORICAL VARIABLES:\n")
print(desc_categorical)
cat("\n\nVOLUNTARY ASSOCIATION MEMBERSHIPS (2004 only):\n")
print(desc_memberships)

# ============================================================================
# CREATE LaTeX TABLE
# ============================================================================

latex_table <- "
\\\\begin{table}[htbp]
\\\\centering
\\\\caption{Descriptive Statistics for Variables Used in Analysis}
\\\\label{tab:descriptives}
\\\\begin{tabular}{lcccc}
\\\\toprule
\\\\textbf{Continuous Variables} & \\\\textbf{Mean} & \\\\textbf{Std. Dev.} & \\\\textbf{Min} & \\\\textbf{Max} \\\\\\\\
\\\\midrule
"

# Add continuous variables
for (i in seq_len(nrow(desc_continuous))) {
  row <- desc_continuous[i, ]
  latex_table <- paste0(
    latex_table,
    row$variable, " & ",
    format(row$mean, nsmall = 2), " & ",
    format(row$sd, nsmall = 2), " & ",
    format(row$min, nsmall = 1), " & ",
    format(row$max, nsmall = 1), " \\\\\\\\\n"
  )
}

latex_table <- paste0(
  latex_table,
  "\\\\midrule\n",
  "\\\\textbf{Categorical Variables} & \\\\textbf{\\\\% Yes} & & & \\\\\\\\\n",
  "\\\\midrule\n"
)

# Add categorical variables
for (i in seq_len(nrow(desc_categorical))) {
  row <- desc_categorical[i, ]
  latex_table <- paste0(
    latex_table,
    row$variable, " & ",
    format(row$pct_yes, nsmall = 1), "\\\\% & & & \\\\\\\\\n"
  )
}

latex_table <- paste0(
  latex_table,
  "\\\\midrule\n",
  "\\\\textbf{Voluntary Association Memberships} & \\\\textbf{\\\\% Yes} & & & \\\\\\\\\n",
  "\\\\midrule\n"
)

# Add membership variables
for (i in seq_len(nrow(desc_memberships))) {
  row <- desc_memberships[i, ]
  latex_table <- paste0(
    latex_table,
    row$membership_type, " & ",
    format(row$pct_member, nsmall = 1), "\\\\% & & & \\\\\\\\\n"
  )
}

latex_table <- paste0(
  latex_table,
  "\\\\bottomrule\n",
  "\\\\end{tabular}\n",
  "\\\\end{table}\n"
)

# Write to file
writeLines(latex_table, "Tabs/tbl-descriptives.tex")

cat("\n" %+% strrep("=", 70) %+% "\n")
cat("✓ Descriptive statistics table generated: Tabs/tbl-descriptives.tex\n")
cat(strrep("=", 70) %+% "\n")

# ============================================================================
# PRINT TO CONSOLE FOR VERIFICATION
# ============================================================================

cat("\nDESCRIPTIVE STATISTICS SUMMARY:\n\n")
cat("Continuous Variables (Pooled 1996/2004):\n")
cat(sprintf("  U.S. Pride Scale:      M = %.2f, SD = %.2f, range [%.0f, %.0f]\n",
            desc_continuous$mean[1], desc_continuous$sd[1], 
            desc_continuous$min[1], desc_continuous$max[1]))
cat(sprintf("  Nationalism Scale:     M = %.2f, SD = %.2f, range [%.0f, %.0f]\n",
            desc_continuous$mean[2], desc_continuous$sd[2],
            desc_continuous$min[2], desc_continuous$max[2]))
cat(sprintf("  Education (Years):     M = %.2f, SD = %.2f, range [%.0f, %.0f]\n",
            desc_continuous$mean[3], desc_continuous$sd[3],
            desc_continuous$min[3], desc_continuous$max[3]))
cat(sprintf("  Birth Cohort:          M = %.2f, SD = %.2f, range [%.0f, %.0f]\n",
            desc_continuous$mean[4], desc_continuous$sd[4],
            desc_continuous$min[4], desc_continuous$max[4]))
cat(sprintf("  Total Memberships:     M = %.2f, SD = %.2f, range [%.0f, %.0f]\n",
            desc_continuous$mean[5], desc_continuous$sd[5],
            desc_continuous$min[5], desc_continuous$max[5]))
