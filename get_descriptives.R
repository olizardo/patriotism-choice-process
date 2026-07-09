library(gssr)
library(dplyr)
library(tidyr)
#library(weights) # For wtd.mean, wtd.var etc. if needed, or just standard for descriptives

# Load same data as generate_tables.R
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
  filter(!is.na(wtssall))

# Calculate descriptives for table (unweighted is fine for descriptive statistics table, or I can use weighted)
desc_cont <- function(var) {
  v <- gss_clean[[var]]
  v <- v[!is.na(v)]
  c(mean(v), sd(v), min(v), max(v))
}

vars_cont <- c("uspridescal", "nationalistscal", "educ", "memnum", "cohort", "age")
sapply(vars_cont, desc_cont)

cat("\n-- Binary Variables --\n")
desc_bin <- function(var) {
  v <- gss_clean[[var]]
  v <- v[!is.na(v)]
  mean(v == 1) * 100
}
vars_bin <- c("south", "conservative")
sapply(vars_bin, desc_bin)

cat("\n-- Categorical --\n")
cat("Sex: ", prop.table(table(gss_clean$sex)) * 100, "\n")
cat("Race: ", prop.table(table(gss_clean$race)) * 100, "\n")

