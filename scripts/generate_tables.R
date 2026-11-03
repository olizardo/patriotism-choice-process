library(gssr)
library(dplyr)
library(tidyr)
library(modelsummary)

source("scripts/00_utils.R")

gss_comb <- gss_load_comb()

gss_clean <- gss_clean_data(gss_comb,
                            pride_filter = "all_missing",
                            memnum_dk_as_zero = FALSE)

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
write_table_booktabs(
  "Tabs/tbl-nationalism.tex", caption = "Predictors of Nationalism Scale (1996 vs 2004)", label = "tab:nationalism",
  models = list("Base Change" = mod_nat_base, "Educ Interaction" = mod_nat_int),
  stars = TRUE, coef_map = coef_labels,

)

mod_educ_96 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 1996, weights = wtssall)
mod_educ_04 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_educ_interaction <- lm(uspridescal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
write_table_booktabs(
  "Tabs/tbl-regression-educ.tex", caption = "Effects of Education on U.S. Pride Scale (1996 vs 2004)", label = "tab:educ",
  models = list("1996" = mod_educ_96, "2004" = mod_educ_04, "Pooled Interaction" = mod_educ_interaction),
  stars = TRUE, coef_map = coef_labels,

)

mod_base <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_mem_cat <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnumcat, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_mem_cont <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_full <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum + nationalistscal, data = gss_clean, subset = year == 2004, weights = wtssall)
write_table_booktabs(
  "Tabs/tbl-regression-full-2004.tex", caption = "Predictors of U.S. Pride (2004 sample only)", label = "tab:full2004",
  models = list("Demographics" = mod_base, "Mem (Cat)" = mod_mem_cat, "Mem (Count)" = mod_mem_cont, "Full (+ Nat)" = mod_full),
  stars = TRUE, coef_map = coef_labels,

)

# APPENDIX MODELS (with conservative, dropping NAs on conservative, ONLY 1996)
# These results are reported in footnote 2 of the manuscript and reproduced
# by scripts/supplementary_analysis_footnote2.R; see that script for the
# 1996 subsample models with the conservative ideology control.

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

# Original proud* items (not dichotomized): the same 10 items that make up
# uspridescal (prouddembin:proudgrpbin)
pride_items_orig <- gss_clean %>% 
  select(prouddem, proudpol, proudeco, proudsss, proudsci, proudspt,
         proudart, proudmil, proudhis, proudgrp) %>%
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

