library(gssr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(broom)

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
    uspridescal_continuous = if(any(is.na(c_across(prouddem:proudgrp)))) NA_real_
                              else mean(c_across(prouddem:proudgrp), na.rm = TRUE),
    nationalistscal = 6 - mean(c_across(c(amcitizn, belikeus, ambetter, ifwrong)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(!is.na(wtssall)) %>%
  mutate(
    year_f = factor(year),
    sex_f = factor(sex),
    race_f = factor(race)
  )

cat("Data loaded and cleaned. Generating figures...\n\n")

# ============================================================================
# FIGURE 1: Item-Level Odds Ratios (Logistic Regression)
# ============================================================================
# Shows the increase in likelihood of being "very proud" post-9/11 for each item
# Odds ratios > 1 indicate increased odds of "very proud" in 2004 vs 1996

cat("Generating Figure 1: Item-level logistic regression odds ratios...\n")

pride_items <- c(
  "prouddem" = "Democracy Works",
  "proudpol" = "Political Influence",
  "proudgen" = "Economic Achievements",
  "proudartsci" = "Science & Tech",
  "proudeduc" = "Education",
  "proudtradeuniv" = "Trade Universities",
  "proudsports" = "Sports",
  "proudparks" = "Parks/Recreation",
  "proudgrp" = "Fair Treatment",
  "proudarmed" = "Armed Forces"
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
  scale_x_continuous(breaks = seq(1, 4, by = 0.5), limits = c(0.8, 4.2)) +
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
    title = "Distribution of U.S. Pride Scale Scores (1996 vs. 2004)",
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

# Fit the main model
mod_educ_interaction <- lm(uspridescal ~ educ * year_f + cohort, 
                            data = gss_clean, weights = wtssall)

# Create prediction grid
pred_grid <- expand_grid(
  educ = seq(0, 20, by = 1),
  year_f = factor(c(1996, 2004)),
  cohort = mean(gss_clean$cohort, na.rm = TRUE)
)

# Generate predictions with confidence intervals
pred_se <- predict(mod_educ_interaction, newdata = pred_grid, se.fit = TRUE)
pred_data <- pred_grid %>%
  mutate(
    fit = pred_se$fit,
    se = pred_se$se.fit,
    ci_lower = fit - 1.96 * se,
    ci_upper = fit + 1.96 * se,
    year = as.character(year_f)
  )

# Color scheme
colors <- c("1996" = "#E07B8C", "2004" = "#4DB8E8")
fills <- c("1996" = "#F5CCCE", "2004" = "#D4E8F5")

fig_marginal <- ggplot(pred_data, aes(x = educ, y = fit, color = year, fill = year)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.3, color = NA) +
  geom_line(linewidth = 1.2) +
  scale_color_manual(values = colors, name = "Year") +
  scale_fill_manual(values = fills, name = "Year") +
  scale_x_continuous(breaks = seq(0, 20, by = 5), limits = c(0, 20)) +
  scale_y_continuous(limits = c(2.5, 5.5)) +
  labs(
    title = "Predicted U.S. Pride Score across Education Levels by Year",
    x = "Years of Education",
    y = "Predicted U.S. Pride Score"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = c(0.9, 0.2),
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
  "memhobbyin" = "Hobby Club",
  "memschoolbin" = "School Service",
  "memlitbookbin" = "Literary/Art Group",
  "memservbin" = "Service Club",
  "memyouthbin" = "Youth Group",
  "memfarmbin" = "Farm Organization",
  "mempoliticalbin" = "Political Club",
  "memlaborbin" = "Labor Union",
  "memprofbin" = "Professional Society",
  "memfratbin" = "School Fraternity",
  "memsportsbin" = "Sports Group",
  "memfraterbinorg" = "Fraternal Group",
  "memveteransbin" = "Veterans Group",
  "memnationalitybin" = "Nationality Group"
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
  scale_x_continuous(breaks = seq(0, 2, by = 0.5), limits = c(-0.5, 2.2)) +
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
cat("\nAll figures are now reproducible from the canonical data pipeline.\n")
