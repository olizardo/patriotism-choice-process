library(gssr)
library(dplyr)
library(tidyr)
library(modelsummary)

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
  filter(if_all(prouddem:proudgrp, ~ .x != 0 | is.na(.x))) %>%
  mutate(
    across(ambornin:amsports, ~ na_if(.x, 0)),
    across(ambornin:amsports, ~ na_if(.x, 9)),
    across(prouddem:proudgrp, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
    across(ambornin:amfeel, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
    across(c(amcitizn, amshamed, belikeus, ambetter, ifwrong), ~ ifelse(.x == 8, 3, .x)),
    across(c(amcitizn, amshamed, belikeus, ambetter, ifwrong), ~ ifelse(.x < 3, 1, 0), .names = "{.col}bin"),
    educ = ifelse(educ %in% c(98, 99), NA, educ),
    degree = ifelse(degree %in% c(8, 9), NA, degree),
    memnum = ifelse(memnum == -1, NA, ifelse(memnum %in% c(98, 99), 0, memnum)),
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
    patriotscal = if(any(is.na(c_across(c(amborninbin, amcitbin, amlivedbin, amgovtbin, amfeelbin))))) NA_real_ 
                  else sum(c_across(c(amborninbin, amcitbin, amlivedbin, amgovtbin, amfeelbin))),
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

mod_educ_96 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 1996, weights = wtssall)
mod_educ_04 <- lm(uspridescal ~ educ + cohort, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_educ_interaction <- lm(uspridescal ~ educ * year_f + cohort, data = gss_clean, weights = wtssall)
modelsummary(list("1996" = mod_educ_96, "2004" = mod_educ_04, "Pooled Interaction" = mod_educ_interaction), 
             stars = TRUE, coef_map = coef_labels, 
             title = "Effects of Education on U.S. Pride Scale (1996 vs 2004)",
             output = "Tabs/tbl-regression-educ.tex")

mod_base <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_mem_cat <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnumcat, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_mem_cont <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum, data = gss_clean, subset = year == 2004, weights = wtssall)
mod_full <- lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnum + nationalistscal, data = gss_clean, subset = year == 2004, weights = wtssall)
modelsummary(list("Demographics" = mod_base, "Mem (Cat)" = mod_mem_cat, "Mem (Count)" = mod_mem_cont, "Full (+ Nat)" = mod_full), 
             stars = TRUE, coef_map = coef_labels, 
             title = "Predictors of U.S. Pride (2004 sample only)",
             output = "Tabs/tbl-regression-full-2004.tex")

# APPENDIX MODELS (with conservative, dropping NAs on conservative, ONLY 1996)
gss_cons_96 <- gss_clean %>% filter(year == 1996 & !is.na(conservative))

mod_nat_base_app <- lm(nationalistscal ~ cohort + conservative, data = gss_cons_96, weights = wtssall)
mod_nat_int_app <- lm(nationalistscal ~ educ + cohort + conservative, data = gss_cons_96, weights = wtssall)
modelsummary(list("Base Change" = mod_nat_base_app, "With Educ" = mod_nat_int_app),
             stars = TRUE, coef_map = coef_labels, 
             title = "Predictors of Nationalism Scale (1996 Subsample with Ideology)",
             output = "Tabs/tbl-app-nationalism.tex")

mod_educ_96_app <- lm(uspridescal ~ educ + cohort + conservative, data = gss_cons_96, weights = wtssall)
modelsummary(list("1996" = mod_educ_96_app), 
             stars = TRUE, coef_map = coef_labels, 
             title = "Effects of Education on U.S. Pride Scale (1996 Subsample with Ideology)",
             output = "Tabs/tbl-app-regression-educ.tex")

