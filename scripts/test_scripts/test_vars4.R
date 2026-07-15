library(gssr)
gss04 <- gss_get_yr(2004)
cat(intersect(c("sei", "race", "sex", "prestg80"), names(gss04)))
