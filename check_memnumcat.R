library(dplyr)
# Let's recreate gss_clean to see the levels of memnumcat
library(gssr)
gss96 <- gss_get_yr(1996)
gss04 <- gss_get_yr(2004)
gss_comb <- bind_rows(gss96, gss04) %>% filter(year %in% c(1996, 2004))
gss_clean <- gss_comb %>%
  mutate(across(everything(), as.numeric)) %>%
  filter(if_all(prouddem:proudgrp, ~ .x != 0 | is.na(.x))) %>%
  mutate(
    memnum = ifelse(memnum == -1, NA, ifelse(memnum %in% c(98, 99), 0, memnum)),
    memnumcat = case_when(
      memnum == 0 ~ "0",
      memnum %in% 1:2 ~ "1-2", 
      memnum >= 3 ~ "3+", 
      TRUE ~ NA_character_
    ),
    memnumcat = factor(memnumcat, levels = c("0", "1-2", "3+"))
  )
table(gss_clean$memnumcat, useNA="always")
