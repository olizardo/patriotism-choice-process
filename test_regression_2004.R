library(dplyr)
library(haven)
library(broom)

# Oh wait, we didn't save gss_clean. Let's recreate it to test what's missing
library(gssr)
gss96 <- gss_get_yr(1996)
gss04 <- gss_get_yr(2004)
vars_to_keep <- c("year", "age", "educ", "degree", "sex", "race", "polviews", "born", 
                  "reg16", "region", "sei", "wtssall", "belikeus", "ifwrong")
gss_comb <- bind_rows(gss96, gss04) %>%
  select(any_of(vars_to_keep), starts_with("proud"), starts_with("am"), starts_with("mem")) %>%
  filter(year %in% c(1996, 2004))
gss_clean <- gss_comb %>%
  mutate(across(everything(), as.numeric)) %>%
  filter(if_all(prouddem:proudgrp, ~ .x != 0 | is.na(.x))) %>%
  mutate(
    across(ambornin:amsports, ~ na_if(.x, 0)),
    across(ambornin:amsports, ~ na_if(.x, 9)),
    across(prouddem:proudgrp, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
    across(c(amcitizn, amshamed, belikeus, ambetter, ifwrong), ~ ifelse(.x == 8, 3, .x)),
    educ = ifelse(educ %in% c(98, 99), NA, educ),
    sex_f = factor(sex),
    race_f = factor(race),
    cohort = year - age,
    south = ifelse(reg16 > 4 & region < 8, 1, 0),
    memnum = ifelse(memnum == -1, NA, ifelse(memnum %in% c(98, 99), 0, memnum)),
    memnumcat = case_when(memnum %in% 1:2 ~ "1-2", memnum >= 3 ~ "3+", TRUE ~ NA_character_),
    memnumcat = factor(memnumcat, levels = c("1-2", "3+"))
  ) %>%
  rowwise() %>%
  mutate(
    uspridescal = if(any(is.na(c_across(prouddembin:proudgrpbin)))) NA_real_ else sum(c_across(prouddembin:proudgrpbin)),
    nationalistscal = 6 - mean(c_across(c(amcitizn, belikeus, ambetter, ifwrong)), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(!is.na(wtssall))

# Slide 36:
summary(lm(uspridescal ~ educ + cohort + sex_f + race_f + south + memnumcat, data = gss_clean, subset=year==2004, weights=wtssall))

