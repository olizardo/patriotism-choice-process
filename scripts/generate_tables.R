library(gssr)
library(dplyr)
library(tidyr)
library(modelsummary)

# ASA style: omit leading zeros on numbers that cannot exceed 1 in magnitude
# (e.g., coefficients, SEs, p-value thresholds), and prefix the significance
# note with "Note:" per the ASA manuscript preparation checklist.
format_table_asa_style <- function(path, label = NULL) {
  lines <- readLines(path)
  lines <- gsub("(?<![0-9.])(-?)0\\.([0-9]*[1-9][0-9]*)", "\\1.\\2", lines, perl = TRUE)
  lines <- sub("(note\\{\\}=\\{)(?!Note: )", "\\1Note: ", lines, perl = TRUE)
  if (!is.null(label) && !any(grepl(paste0("label=\\{", label, "\\}"), lines))) {
    caption_idx <- grep("^caption=\\{", lines)[1]
    lines <- append(lines, paste0("label={", label, "},"), after = caption_idx)
  }
  writeLines(lines, path)
}

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
  # Exclude rows where ALL pride items are missing (listwise deletion at scale level)
  filter(!if_all(prouddem:proudgrp, ~ is.na(.x))) %>%
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
    # Do NOT dichotomize nationalism items; keep them for mean calculation
    educ = ifelse(educ %in% c(98, 99), NA, educ),
    degree = ifelse(degree %in% c(8, 9), NA, degree),
    # Treat -1 as missing, and 98/99 (DK/refused) as NA (not as 0 memberships)
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
    # U.S. Pride Scale: sum of dichotomized items (0-10), counts "very proud" responses
    uspridescal = if(any(is.na(c_across(prouddembin:proudgrpbin)))) NA_real_ 
                  else sum(c_across(prouddembin:proudgrpbin)),
    # U.S. Pride Scale (continuous): mean of un-dichotomized pride items
    # Used for robustness check: values range from 1-4 (original response scale)
    uspridescal_continuous = if(any(is.na(c_across(prouddem:proudgrp)))) NA_real_
                              else mean(c_across(prouddem:proudgrp), na.rm = TRUE),
    # Nationalism Scale: mean of 4 reverse-coded items on 1-5 Likert scale (higher = more nationalist)
    # Items: amcitizn, belikeus, ambetter, ifwrong
    # Original coding: 1=Strongly Agree, 5=Strongly Disagree
    # Reverse-coded: 6 - original value, so 1→5, 5→1 (Agree→high, Disagree→low)
    # Formula: 6 - mean() reverses the scale so higher values = stronger nationalism
    nationalistscal = 6 - mean(c_across(c(amcitizn, belikeus, ambetter, ifwrong)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(!is.na(wtssall)) %>%
  mutate(
    year_f = factor(year),
    sex_f = factor(sex),
    race_f = factor(race)
  )

coef_labels <- c(
  "educ" = "Education (Years)",
  "cohort" = "Birth Cohort",
  "year_f2004" = "Year: 2004",
  "educ:year_f2004" = "Education × Year 2004",
  "sei" = "Occupational Status (SEI)",
  "sex_f2" = "Female",
  "race_f2" = "Race: Black",
  "race_f3" = "Race: Other",
  "south" = "Region: South",
  "nationalistscal" = "Nationalist Scale",
  "memnum" = "Total Memberships (Count)",
  "memnumcat1-2" = "Memberships: 1-2",
  "memnumcat3+" = "Memberships: 3+",
  "conservative" = "Political Ideology (Conservative)",
  "(Intercept)" = "Intercept"
)

# MAIN MODELS (no conservative)
mod_nat_base <- lm(nationalistscal ~ year_f + cohort, data = gss_clean, weights = wtssall)
mod_nat_int <- lm(nationalistscal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
modelsummary(list("Base Change" = mod_nat_base, "Educ Interaction" = mod_nat_int),
             stars = TRUE, coef_map = coef_labels, 
             title = "Predictors of Nationalism Scale (1996 vs 2004)",
             output = "Tabs/tbl-nationalism.tex")
format_table_asa_style("Tabs/tbl-nationalism.tex", "tab:nationalism")

mod_educ_96 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 1996, weights = wtssall)
mod_educ_04 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_educ_interaction <- lm(uspridescal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
modelsummary(list("1996" = mod_educ_96, "2004" = mod_educ_04, "Pooled Interaction" = mod_educ_interaction), 
             stars = TRUE, coef_map = coef_labels, 
             title = "Effects of Education on U.S. Pride Scale (1996 vs 2004)",
             output = "Tabs/tbl-regression-educ.tex")
format_table_asa_style("Tabs/tbl-regression-educ.tex", "tab:educ")

mod_base <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_mem_cat <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnumcat, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_mem_cont <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_full <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum + nationalistscal, data = gss_clean, subset = year == 2004, weights = wtssall)
modelsummary(list("Demographics" = mod_base, "Mem (Cat)" = mod_mem_cat, "Mem (Count)" = mod_mem_cont, "Full (+ Nat)" = mod_full), 
             stars = TRUE, coef_map = coef_labels, 
             title = "Predictors of U.S. Pride (2004 sample only)",
             output = "Tabs/tbl-regression-full-2004.tex")
format_table_asa_style("Tabs/tbl-regression-full-2004.tex", "tab:full2004")

# APPENDIX MODELS (with conservative, dropping NAs on conservative, ONLY 1996)
gss_cons_96 <- gss_clean %>% filter(year == 1996 & !is.na(conservative))

mod_nat_base_app <- lm(nationalistscal ~ cohort + conservative, data = gss_cons_96, weights = wtssall)
mod_nat_int_app <- lm(nationalistscal ~ educ + cohort + conservative, data = gss_cons_96, weights = wtssall)
modelsummary(list("Base Change" = mod_nat_base_app, "With Educ" = mod_nat_int_app),
             stars = TRUE, coef_map = coef_labels, 
             title = "Predictors of Nationalism Scale (1996 Subsample with Ideology)",
             output = "Tabs/tbl-app-nationalism.tex")
format_table_asa_style("Tabs/tbl-app-nationalism.tex")

mod_educ_96_app <- lm(uspridescal ~ educ + cohort + conservative, data = gss_cons_96, weights = wtssall)
modelsummary(list("1996" = mod_educ_96_app), 
             stars = TRUE, coef_map = coef_labels, 
             title = "Effects of Education on U.S. Pride Scale (1996 Subsample with Ideology)",
             output = "Tabs/tbl-app-regression-educ.tex")
format_table_asa_style("Tabs/tbl-app-regression-educ.tex")

# ROBUSTNESS CHECK: Non-dichotomized U.S. Pride Scale
# Verify correlation between dichotomized and continuous scales
corr_scales <- cor(gss_clean$uspridescal, gss_clean$uspridescal_continuous, use = "complete.obs")
cat("\n=== ROBUSTNESS CHECK: Continuous U.S. Pride Scale ===\n")
cat("Correlation between dichotomized and continuous pride scales: r =", round(corr_scales, 2), "\n")

# Re-estimate education × year interaction model on continuous scale
mod_educ_interaction_cont <- lm(uspridescal_continuous ~ educ * year_f + cohort, 
                                 data = gss_clean, weights = wtssall)

# Extract interaction coefficient and test significance under classical and robust SEs
library(sandwich)
library(lmtest)

coef_int <- coef(mod_educ_interaction_cont)["educ:year_f2004"]
se_classical <- sqrt(diag(vcov(mod_educ_interaction_cont)))["educ:year_f2004"]
se_robust <- sqrt(diag(vcovHC(mod_educ_interaction_cont, type = "HC1")))["educ:year_f2004"]

t_classical <- coef_int / se_classical
t_robust <- coef_int / se_robust

p_classical <- 2 * pt(-abs(t_classical), df = nobs(mod_educ_interaction_cont) - length(coef(mod_educ_interaction_cont)))
p_robust <- 2 * pt(-abs(t_robust), df = nobs(mod_educ_interaction_cont) - length(coef(mod_educ_interaction_cont)))

# One-tailed p-value for robust (hypothesis is one-tailed: interaction > 0)
p_robust_onetail <- pt(-abs(t_robust), df = nobs(mod_educ_interaction_cont) - length(coef(mod_educ_interaction_cont)))

cat("\nEducation × Year 2004 interaction coefficient (continuous scale):\n")
cat("  Coefficient:", round(coef_int, 4), "\n")
cat("  SE (classical):", round(se_classical, 4), "\n")
cat("  SE (HC1 robust):", round(se_robust, 4), "\n")
cat("  t-stat (classical):", round(t_classical, 4), "\n")
cat("  t-stat (robust):", round(t_robust, 4), "\n")
cat("  p-value (classical, two-tailed):", round(p_classical, 3), "\n")
cat("  p-value (robust, two-tailed):", round(p_robust, 3), "\n")
cat("  p-value (robust, one-tailed):", round(p_robust_onetail, 3), "\n")

# Compare full models side-by-side for interpretation
cat("\n\nFull model comparison (dichotomized vs. continuous pride scale):\n")
print(summary(mod_educ_interaction))
cat("\n---\n")
print(summary(mod_educ_interaction_cont))

# ============================================================================
# COMPREHENSIVE NUMERICAL AUDIT: Verify all claims in the manuscript
# ============================================================================
cat("\n\n" %+% strrep("=", 70) %+% "\n")
cat("NUMERICAL AUDIT: Manuscript Claim Verification\n")
cat(strrep("=", 70) %+% "\n\n")

# Cronbach's alphas for the main scales
library(psych)
pride_items <- gss_clean %>% 
  select(starts_with("prouddem"), starts_with("proudeco"), starts_with("proudgov"), 
         starts_with("proudart"), starts_with("proudsci"), starts_with("proudspo"),
         starts_with("proudarmed"), starts_with("proudhist"), starts_with("proudfair"),
         starts_with("proudgrp")) %>%
  select(matches("^proud[a-z]+$"))

# More robust way: get the original proud* items (not dichotomized)
pride_items_orig <- gss_clean %>% 
  select(prouddem, proudeco, proudgen, proudartsci, proudeduc, 
         proudtradeuniv, proudsports, proudparks, proudgrp, proudarmed) %>%
  mutate(across(everything(), as.numeric))

nationalism_items <- gss_clean %>%
  select(amcitizn, belikeus, ambetter, ifwrong) %>%
  mutate(across(everything(), as.numeric))

cronbach_pride <- alpha(pride_items_orig, warnings = FALSE)$total$raw_alpha
cronbach_nationalism <- alpha(nationalism_items, warnings = FALSE)$total$raw_alpha

cat("SCALE RELIABILITY:\n")
cat(sprintf("  U.S. Pride Scale Cronbach's α: %.2f (reported: .80)\n", cronbach_pride))
cat(sprintf("  Nationalism Scale Cronbach's α: %.2f (reported: .64)\n", cronbach_nationalism))
cat("\n")

# Descriptive statistics
cat("DESCRIPTIVE STATISTICS (pooled 1996/2004):\n")
desc_stats <- gss_clean %>%
  summarise(
    pride_mean = mean(uspridescal, na.rm = TRUE),
    pride_sd = sd(uspridescal, na.rm = TRUE),
    pride_min = min(uspridescal, na.rm = TRUE),
    pride_max = max(uspridescal, na.rm = TRUE),
    nat_mean = mean(nationalistscal, na.rm = TRUE),
    nat_sd = sd(nationalistscal, na.rm = TRUE),
    nat_min = min(nationalistscal, na.rm = TRUE),
    nat_max = max(nationalistscal, na.rm = TRUE),
    educ_mean = mean(educ, na.rm = TRUE),
    educ_sd = sd(educ, na.rm = TRUE),
    memnum_mean = mean(memnum, na.rm = TRUE),
    memnum_sd = sd(memnum, na.rm = TRUE)
  )

cat(sprintf("  U.S. Pride: M = %.2f, SD = %.2f, range [%.1f, %.1f] (reported: 3.88 ± 2.79, [0.0, 10.0])\n",
            desc_stats$pride_mean, desc_stats$pride_sd, desc_stats$pride_min, desc_stats$pride_max))
cat(sprintf("  Nationalism: M = %.2f, SD = %.2f, range [%.1f, %.1f] (reported: 3.72 ± .71, [1.0, 5.0])\n",
            desc_stats$nat_mean, desc_stats$nat_sd, desc_stats$nat_min, desc_stats$nat_max))
cat(sprintf("  Education: M = %.2f, SD = %.2f, range [%.1f, %.1f] (reported: 13.53 ± 2.91, [0.0, 20.0])\n",
            desc_stats$educ_mean, desc_stats$educ_sd, min(gss_clean$educ, na.rm=T), max(gss_clean$educ, na.rm=T)))
cat(sprintf("  Total Memberships: M = %.2f, SD = %.2f (reported: 1.61 ± 1.88)\n",
            desc_stats$memnum_mean, desc_stats$memnum_sd))
cat("\n")

# Model-specific claims: interaction p-values
cat("KEY MODEL RESULTS:\n")
cat("Education × Year 2004 Interaction Effects:\n")

# 1. Nationalism interaction
mod_nat_int <- lm(nationalistscal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
sum_nat <- summary(mod_nat_int)
nat_int_pval <- sum_nat$coefficients["educ:year_f2004", "Pr(>|t|)"]
cat(sprintf("  Nationalism interaction p-value: %.4f (reported: clearly non-significant)\n", nat_int_pval))

# 2. U.S. Pride interaction (classical SEs)
mod_pride_int <- lm(uspridescal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
sum_pride <- summary(mod_pride_int)
pride_int_coef <- sum_pride$coefficients["educ:year_f2004", "Estimate"]
pride_int_se_classical <- sum_pride$coefficients["educ:year_f2004", "Std. Error"]
pride_int_pval_classical <- sum_pride$coefficients["educ:year_f2004", "Pr(>|t|)"]

cat(sprintf("  U.S. Pride interaction coef: %.4f (Footnote 1 reports positive direction)\n", pride_int_coef))
cat(sprintf("  U.S. Pride interaction p-value (classical): %.4f (reported: .021 robust)\n", pride_int_pval_classical))

# 3. U.S. Pride 1996-only education effect
mod_pride_96 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 1996, weights = wtssall)
sum_96 <- summary(mod_pride_96)
pride_96_pval <- sum_96$coefficients["educ", "Pr(>|t|)"]
cat(sprintf("  1996 education effect p-value: %.4f (reported: p = .030)\n", pride_96_pval))

# Robust SEs comparison
se_robust_pride <- sqrt(diag(vcovHC(mod_pride_int, type = "HC1")))["educ:year_f2004"]
se_ratio <- se_robust_pride / pride_int_se_classical
cat(sprintf("\n  Robust / Classical SE ratio for interaction: %.2f (reported: 1.08–1.15)\n", se_ratio))

# Test 1996 education under robust SEs
mod_96_robust_se <- sqrt(diag(vcovHC(mod_pride_96, type = "HC1")))["educ"]
t_96_robust <- sum_96$coefficients["educ", "Estimate"] / mod_96_robust_se
p_96_robust <- 2 * pt(-abs(t_96_robust), df = nobs(mod_pride_96) - length(coef(mod_pride_96)))
cat(sprintf("  1996 education effect p-value (robust): %.4f (reported: p = .055)\n", p_96_robust))

cat("\n" %+% strrep("=", 70) %+% "\n")
cat("END OF NUMERICAL AUDIT\n")
cat(strrep("=", 70) %+% "\n")

