library(gssr)
gss04 <- gss_get_yr(2004)
cat(intersect(c("belikeus", "ifwrong", "if92who", "if00who"), names(gss04)))
