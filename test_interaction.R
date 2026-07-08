library(gssr)
library(dplyr)
library(tidyr)
gss96 <- gss_get_yr(1996)
gss04 <- gss_get_yr(2004)
gss_comb <- bind_rows(gss96, gss04) %>%
  filter(year %in% c(1996, 2004))
gss_clean <- gss_comb %>%
  mutate(across(everything(), as.numeric)) %>%
  filter(if_all(prouddem:proudgrp, ~ .x != 0 | is.na(.x))) %>%
  mutate(
    across(prouddem:proudgrp, ~ ifelse(.x == 1, 1, 0), .names = "{.col}bin"),
    year_f = factor(year),
    memnum = ifelse(memnum == -1, NA, ifelse(memnum %in% c(98, 99), 0, memnum))
  ) %>%
  mutate(across(memfrat:memchurh, ~ ifelse(.x > 0 & !is.na(.x) & .x == 1, 1, 0), .names = "{.col}bin")) %>%
  rowwise() %>%
  mutate(uspridescal = if(any(is.na(c_across(prouddembin:proudgrpbin)))) NA_real_ else sum(c_across(prouddembin:proudgrpbin))) %>%
  ungroup() %>%
  filter(!is.na(wtssall))

# Overall membership effect
summary(lm(uspridescal ~ memnum * year_f, data = gss_clean, weights = wtssall))

# Specific memberships
mem_bins <- grep("^mem.*bin$", names(gss_clean), value = TRUE)
mem_bins <- setdiff(mem_bins, c("memnumbin", "memotherbin", "memgrp1bin", "memgrp2bin", "memgrp3bin", "memgrp4bin", "memgrp5bin"))

cat("\nInteraction p-values:\n")
for(v in mem_bins) {
  m <- lm(as.formula(paste("uspridescal ~", v, "* year_f")), data = gss_clean, weights = wtssall)
  p <- summary(m)$coefficients
  if(nrow(p) > 3) {
    p_val <- p[4, 4]
    cat(v, ": ", round(p_val, 4), "\n")
  }
}
