library(gssr)
library(dplyr)
library(tidyr)
library(modelsummary)
library(psych)

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
# NUMERICAL AUDIT: Verify statistics reported in the manuscript text
# ============================================================================
cat("\n\n" %+% strrep("=", 70) %+% "\n")
cat("NUMERICAL AUDIT: Manuscript Claim Verification\n")
cat(strrep("=", 70) %+% "\n\n")

# Scale reliability uses the dichotomized items that make up uspridescal
pride_bins <- gss_clean %>% select(prouddembin:proudgrpbin)
nationalism_items <- gss_clean %>% select(amcitizn, belikeus, ambetter, ifwrong)

cat("SCALE RELIABILITY (Cronbach's alpha):\n")
cat(sprintf("  U.S. Pride Scale (dichotomized items): %.3f (text: .80)\n",
            alpha(pride_bins, warnings = FALSE)$total$raw_alpha))
cat(sprintf("  Nationalism Scale: %.3f (text: .64)\n\n",
            alpha(nationalism_items, warnings = FALSE)$total$raw_alpha))

# Descriptive statistics use the Table 1 specification (any_zero pride filter,
# DK/refused memberships coded 0), so they can be compared with the table
gss_desc <- gss_clean_data(gss_comb, pride_filter = "any_zero", memnum_dk_as_zero = TRUE)
cat("DESCRIPTIVE STATISTICS (Table 1 sample):\n")
cat(sprintf("  U.S. Pride: M = %.2f, SD = %.2f, range [%.1f, %.1f] (text: 3.88 ± 2.79, [0.0, 10.0])\n",
            mean(gss_desc$uspridescal, na.rm = TRUE), sd(gss_desc$uspridescal, na.rm = TRUE),
            min(gss_desc$uspridescal, na.rm = TRUE), max(gss_desc$uspridescal, na.rm = TRUE)))
cat(sprintf("  Nationalism: M = %.2f, SD = %.2f, range [%.1f, %.1f] (text: 3.72 ± .71, [1.0, 5.0])\n",
            mean(gss_desc$nationalistscal, na.rm = TRUE), sd(gss_desc$nationalistscal, na.rm = TRUE),
            min(gss_desc$nationalistscal, na.rm = TRUE), max(gss_desc$nationalistscal, na.rm = TRUE)))
cat(sprintf("  Education: M = %.2f, SD = %.2f, range [%.1f, %.1f] (text: 13.53 ± 2.91, [0.0, 20.0])\n",
            mean(gss_desc$educ, na.rm = TRUE), sd(gss_desc$educ, na.rm = TRUE),
            min(gss_desc$educ, na.rm = TRUE), max(gss_desc$educ, na.rm = TRUE)))
cat(sprintf("  Total Memberships: M = %.2f, SD = %.2f (text: 1.61 ± 1.88)\n",
            mean(gss_desc$memnum, na.rm = TRUE), sd(gss_desc$memnum, na.rm = TRUE)))
cat(sprintf("  Birth cohort: M = %.2f (text: birth cohort is not centered)\n\n",
            mean(gss_desc$cohort, na.rm = TRUE)))

# Model-specific claims (Analytic Strategy and Results)
cat("KEY MODEL RESULTS (classical SEs; HC1 robust SEs in brackets):\n")

m_nat_int <- lm(nationalistscal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
cat(sprintf("  Nationalism Educ x 2004: b = %.4f, p = %.4f (text: b = -.0004, p = .964)\n",
            coef(m_nat_int)["educ:year_f2004"],
            summary(m_nat_int)$coefficients["educ:year_f2004", "Pr(>|t|)"]))

m_pride_int <- lm(uspridescal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
int_hc1 <- coef(summary(m_pride_int))["educ:year_f2004", "Estimate"] /
  sqrt(diag(vcovHC(m_pride_int, type = "HC1")))["educ:year_f2004"]
cat(sprintf("  Pride Educ x 2004: b = %.4f, p = %.4f [HC1 p = %.4f] (text: b = .114, p = .010; robust p = .021)\n",
            coef(m_pride_int)["educ:year_f2004"],
            summary(m_pride_int)$coefficients["educ:year_f2004", "Pr(>|t|)"],
            2 * pt(-abs(int_hc1), df = nobs(m_pride_int) - length(coef(m_pride_int)))))

m_pride_96 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 1996, weights = wtssall)
m_pride_04 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 2004, weights = wtssall)
cat(sprintf("  Pride Educ, 1996: b = %.4f, p = %.4f (text: b = -.066, p = .030)\n",
            coef(m_pride_96)["educ"], summary(m_pride_96)$coefficients["educ", "Pr(>|t|)"]))
cat(sprintf("  Pride Educ, 2004: b = %.4f, p = %.4f (text: b = .040, p = .213)\n",
            coef(m_pride_04)["educ"], summary(m_pride_04)$coefficients["educ", "Pr(>|t|)"]))

# Robust/classical SE ratio across the focal models (text: about 11-17%)
focal <- list(
  `Pride interaction` = m_pride_int,
  `Nationalism interaction` = m_nat_int,
  `1996 educ` = m_pride_96
)
term_for <- c("Pride interaction" = "educ:year_f2004",
              "Nationalism interaction" = "educ:year_f2004",
              "1996 educ" = "educ")
for (nm in names(focal)) {
  t <- term_for[[nm]]
  cat(sprintf("  SE ratio (HC1/classical), %s: %.3f\n", nm,
              sqrt(diag(vcovHC(focal[[nm]], type = "HC1")))[t] /
                sqrt(diag(vcov(focal[[nm]])))[t]))
}

m_cnt <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum,
            data = gss_clean, subset = year == 2004, weights = wtssall)
m_full <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum + nationalistscal,
             data = gss_clean, subset = year == 2004, weights = wtssall)
hc1_p <- function(m, term) {
  b <- coef(m)[term]
  se <- sqrt(diag(vcovHC(m, type = "HC1")))[term]
  2 * pt(-abs(b / se), df = nobs(m) - length(coef(m)))
}
cat(sprintf("  Count model memnum: b = %.4f, p = %.4f (text: b = .115, p = .011)\n",
            coef(m_cnt)["memnum"], summary(m_cnt)$coefficients["memnum", "Pr(>|t|)"]))
cat(sprintf("  Full model memnum: b = %.4f, p = %.4f, HC1 p = %.4f (text: robust p = .027)\n\n",
            coef(m_full)["memnum"], summary(m_full)$coefficients["memnum", "Pr(>|t|)"],
            hc1_p(m_full, "memnum")))

cat("\n" %+% strrep("=", 70) %+% "\n")
cat("END OF NUMERICAL AUDIT\n")
cat(strrep("=", 70) %+% "\n")
