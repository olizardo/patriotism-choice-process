library(gssr)

source("scripts/00_utils.R")
library(dplyr)
library(tidyr)
library(ggplot2)
library(broom)
library(forcats)

# ============================================================================
# GENERATE FIGURES: Reproducible pipeline for all manuscript figures
# ============================================================================
# This script generates all four figures referenced in manuscript_R1.tex:
# 1. fig-logistic-pride.pdf — Item-level odds ratios (logistic regression)
# 2. fig-pride-bar.pdf — Distribution of U.S. Pride scale by year
# 3. fig-marginal-educ.pdf — Predicted U.S. Pride by education × year
# 4. fig-membership-forest.pdf — Effect of specific association types on U.S. Pride
# ============================================================================

# Load and clean data (same as generate_tables.R)
gss_comb <- gss_load_comb()

# Figures 1, 2, 4 use the regression cleaning; Figure 3 reproduces the
# accepted version, which was fit on the any-zero pride filter sample
# (see gss_clean_data() docs in 00_utils.R)
gss_clean <- gss_clean_data(gss_comb,
                            pride_filter = "all_missing",
                            memnum_dk_as_zero = FALSE)

gss_clean_az <- gss_clean_data(gss_comb,
                               pride_filter = "any_zero",
                               memnum_dk_as_zero = FALSE)

cat("Data loaded and cleaned. Generating figures...\n\n")

# ============================================================================
# FIGURE 1: Item-Level Odds Ratios (Logistic Regression)
# ============================================================================
# Shows the increase in likelihood of being "very proud" post-9/11 for each item
# Odds ratios > 1 indicate increased odds of "very proud" in 2004 vs 1996

cat("Generating Figure 1: Item-level logistic regression odds ratios...\n")

pride_items <- c(
  "prouddem" = "Democracy",
  "proudpol" = "Political Influence",
  "proudeco" = "Economic Achievements",
  "proudsss" = "Social Security",
  "proudsci" = "Science & Tech",
  "proudspt" = "Sports",
  "proudart" = "Arts & Literature",
  "proudmil" = "Armed Forces",
  "proudhis" = "History",
  "proudgrp" = "Fair Treatment"
)

# Fit logistic regression for each pride item
logistic_results <- tibble()

for (item in names(pride_items)) {
  formula <- as.formula(paste0(item, "bin ~ year_f + cohort + sex_f + race_f + south"))
  model <- glm(formula, data = gss_clean, family = binomial, weights = wtssall)
  
  or_2004 <- exp(coef(model)["year_f2004"])
  ci <- exp(confint(model)["year_f2004", ])
  
  logistic_results <- bind_rows(logistic_results, tibble(
    item = item,
    label = pride_items[item],
    odds_ratio = or_2004,
    ci_lower = ci[1],
    ci_upper = ci[2]
  ))
}

# Sort by odds ratio for better visualization
logistic_results <- logistic_results %>%
  mutate(label = fct_reorder(label, odds_ratio))

# Plot odds ratios with confidence intervals
fig_logistic <- ggplot(logistic_results, aes(x = odds_ratio, y = label)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "#E31C23", linewidth = 1) +
  geom_point(color = "#003087", size = 3.5) +
  geom_linerange(aes(xmin = ci_lower, xmax = ci_upper), color = "#003087", linewidth = 1) +
  scale_x_continuous(breaks = 1:4, limits = c(0.8, 4.7)) +
  labs(
    title = "Increase in Likelihood of Being 'Very Proud' Post-9/11",
    subtitle = NULL,
    x = "Odds Ratio (2004 vs 1996)",
    y = "Pride Domain"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.margin = margin(10, 15, 10, 10)
  )

ggsave("Plots/fig-logistic-pride.pdf", fig_logistic, width = 10, height = 7.5, dpi = 300)
cat("  ✓ Saved: Plots/fig-logistic-pride.pdf\n")

# ============================================================================
# FIGURE 2: Distribution of U.S. Pride Scale (1996 vs 2004)
# ============================================================================
# Bar chart showing the shift in the distribution of the pride scale

cat("Generating Figure 2: Distribution of U.S. Pride scale by year...\n")

pride_dist <- gss_clean %>%
  filter(!is.na(uspridescal)) %>%
  group_by(year, uspridescal) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(year) %>%
  mutate(proportion = n / sum(n)) %>%
  ungroup() %>%
  mutate(year = as.factor(year))

fig_pride_bar <- ggplot(pride_dist, aes(x = uspridescal, y = proportion, fill = year)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_manual(
    name = "Year",
    values = c("1996" = "#4472C4", "2004" = "#E05C6E"),
    labels = c("1996", "2004")
  ) +
  scale_x_continuous(breaks = 0:10) +
  labs(
    x = "U.S. Pride Scale Score",
    y = "Proportion"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = "top",
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    plot.margin = margin(10, 15, 10, 10)
  )

ggsave("Plots/fig-pride-bar.pdf", fig_pride_bar, width = 10, height = 7, dpi = 300)
cat("  ✓ Saved: Plots/fig-pride-bar.pdf\n")

# ============================================================================
# FIGURE 3: Marginal Effects of Education on U.S. Pride by Year
# ============================================================================
# Predicted U.S. Pride score across education levels, stratified by year

cat("Generating Figure 3: Marginal effects of education on U.S. Pride by year...\n")

# Accepted-spec model: educ x year interaction with cohort control, weighted,
# fit on the any-zero pride-filter sample. Predictions via marginaleffects,
# as in the original analysis; education is centered at 12 years for plotting.
library(marginaleffects)

mod_educ_interaction <- lm(uspridescal ~ educ_c * year_f + cohort,
                            data = mutate(gss_clean_az, educ_c = educ - 12),
                            weights = wtssall)

fig_marginal <- plot_predictions(mod_educ_interaction,
                                 condition = c("educ_c", "year_f")) +
  labs(
    title = "Predicted U.S. Pride Score",
    x = "Education (Centered at 12 Years)",
    y = NULL,
    color = "Year",
    fill = "Year"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = "right",
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    plot.margin = margin(10, 15, 10, 10)
  )

ggsave("Plots/fig-marginal-educ.pdf", fig_marginal, width = 10, height = 7, dpi = 300)
cat("  ✓ Saved: Plots/fig-marginal-educ.pdf\n")

# ============================================================================
# FIGURE 4: Forest Plot of Membership Effects on U.S. Pride
# ============================================================================
# Shows the association between specific membership types and national pride

cat("Generating Figure 4: Membership effects forest plot...\n")

# Fit models for each membership type (2004 only)
gss_2004 <- gss_clean %>% filter(year == 2004)

membership_vars <- c(
  "memhobbybin" = "Hobby Club",
  "memschlbin" = "School Service",
  "memlitbin" = "Literary/Art Group",
  "memservbin" = "Service Club",
  "memyouthbin" = "Youth Group",
  "memfarmbin" = "Farm Organization",
  "mempolitbin" = "Political Club",
  "memunionbin" = "Labor Union",
  "memprofbin" = "Professional Society",
  "memgreekbin" = "School Fraternity",
  "memsportbin" = "Sports Group",
  "memfratbin" = "Fraternal Group",
  "memvetbin" = "Veterans Group",
  "memnatbin" = "Nationality Group",
  "memchurhbin" = "Church Group"
)

membership_results <- tibble()

for (var in names(membership_vars)) {
  if (!var %in% colnames(gss_2004)) next
  
  formula <- as.formula(paste0("uspridescal ~ ", var, " + cohort + sex_f + race_f + south"))
  model <- lm(formula, data = gss_2004, weights = wtssall)
  
  coef_val <- coef(model)[var]
  se_val <- sqrt(diag(vcov(model)))[var]
  
  membership_results <- bind_rows(membership_results, tibble(
    var = var,
    label = membership_vars[var],
    coefficient = coef_val,
    se = se_val,
    ci_lower = coefficient - 1.96 * se,
    ci_upper = coefficient + 1.96 * se
  ))
}

# Remove any with missing values and sort
membership_results <- membership_results %>%
  filter(!is.na(coefficient)) %>%
  mutate(label = fct_reorder(label, coefficient))

# Plot
fig_forest <- ggplot(membership_results, aes(x = coefficient, y = label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#E31C23", linewidth = 1) +
  geom_point(size = 3.5, color = ifelse(membership_results$ci_lower > 0 | membership_results$ci_upper < 0, 
                                          "#27AE60", "#95A5A6")) +
  geom_linerange(aes(xmin = ci_lower, xmax = ci_upper), 
                 color = ifelse(membership_results$ci_lower > 0 | membership_results$ci_upper < 0, 
                               "#27AE60", "#95A5A6"),
                 linewidth = 0.8) +
  scale_x_continuous(breaks = seq(-1, 2, by = 0.5), limits = c(-1.1, 2.1)) +
  labs(
    title = "Effect of Memberships on National Pride",
    x = "Estimate (Change in U.S. Pride Scale)",
    y = "Membership Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.margin = margin(10, 15, 10, 10)
  )

ggsave("Plots/fig-membership-forest.pdf", fig_forest, width = 10, height = 8, dpi = 300)
cat("  ✓ Saved: Plots/fig-membership-forest.pdf\n")

# ============================================================================
# FIGURE 5: Forest Plot of Membership Effects (Demographic Controls, 90/95% CI)
# ============================================================================
# Same models as Figure 4 (cohort, sex, race, South; no education).
# The 90% CI (dark bar) and 95% CI (light bar) are drawn as separate layers.

cat("Generating Figure 5: Membership forest plot with 90/95% CIs...\n")

membership_results_ci <- tibble()

for (var in names(membership_vars)) {
  if (!var %in% colnames(gss_2004)) next

  formula <- as.formula(paste0("uspridescal ~ ", var, " + cohort + sex_f + race_f + south"))
  model <- lm(formula, data = gss_2004, weights = wtssall)

  coef_val <- coef(model)[var]
  se_val <- sqrt(diag(vcov(model)))[var]

  membership_results_ci <- bind_rows(membership_results_ci, tibble(
    var = var,
    label = membership_vars[var],
    coefficient = coef_val,
    lo90 = coef_val - 1.645 * se_val,
    hi90 = coef_val + 1.645 * se_val,
    lo95 = coef_val - 1.96 * se_val,
    hi95 = coef_val + 1.96 * se_val
  ))
}

membership_results_ci <- membership_results_ci %>%
  filter(!is.na(coefficient)) %>%
  mutate(
    # Color code: blue = significant at 95%, medium blue = at 90% only,
    # gray = not significant at either criterion
    sig95 = lo95 > 0 | hi95 < 0,
    sig90 = lo90 > 0 | hi90 < 0,
    col_outer = ifelse(sig95, "#5B8DB8", "#B9B9B9"),
    col_inner = ifelse(sig95, "#1B5E8A", ifelse(sig90, "#5B8DB8", "#8A8A8A")),
    col_point = ifelse(sig95, "#12354F", ifelse(sig90, "#1B5E8A", "#6B6B6B")),
    label = fct_reorder(label, coefficient)
  )

fig_forest_ci <- ggplot(membership_results_ci, aes(x = coefficient, y = label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#E31C23", linewidth = 1) +
  geom_linerange(aes(xmin = lo95, xmax = hi95), color = membership_results_ci$col_outer, linewidth = 0.9, alpha = 0.65) +
  geom_linerange(aes(xmin = lo90, xmax = hi90), color = membership_results_ci$col_inner, linewidth = 2.2) +
  geom_point(size = 3.2, color = membership_results_ci$col_point) +
  scale_x_continuous(breaks = seq(-1, 2, by = 0.5), limits = c(-1.1, 2.1)) +
  labs(
    title = "Effect of Memberships on National Pride",
    subtitle = "Dark bars: 90% CI; light bars: 95% CI. Blue = significant; gray = not significant at either level. 2004 GSS, weighted.",
    x = "Estimate (Change in U.S. Pride Scale)",
    y = "Membership Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.margin = margin(10, 15, 10, 10)
  )

ggsave("Plots/fig-membership-forest-ci.pdf", fig_forest_ci, width = 10, height = 7.5, dpi = 300)
cat("  ✓ Saved: Plots/fig-membership-forest-ci.pdf\n")

# ============================================================================
# SUMMARY
# ============================================================================
cat("\n" %+% strrep("=", 70) %+% "\n")
cat("Figure Generation Complete\n")
cat(strrep("=", 70) %+% "\n")
cat("Generated files:\n")
cat("  1. Plots/fig-logistic-pride.pdf\n")
cat("  2. Plots/fig-pride-bar.pdf\n")
cat("  3. Plots/fig-marginal-educ.pdf\n")
cat("  4. Plots/fig-membership-forest.pdf\n")
cat("  5. Plots/fig-membership-forest-ci.pdf\n")
cat("\nAll figures are now reproducible from the canonical data pipeline.\n")
