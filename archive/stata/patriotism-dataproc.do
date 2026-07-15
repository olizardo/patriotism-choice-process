use born proud* amproud* ambornin amcit amlived amenglsh amchrstn amgovt amfeel amcitizn amshamed belikeus ambetter ifwrong amsports educ degree age paeduc maeduc padeg madeg paocc80 maocc80 pasei masei occ80 sei prestg80 wrkstat sex race mem* memnum year wt* over* region reg16 income98 rincom98 wksup wksups polviews if92who if00who isco* wrkslf using "c:\data\gss-cumulative 1972-2004\gss-cumulative-1972-2004.dta", clear



keep if year==1996|year==2004
for var  prouddem-proudgrp:drop if X==0
for var  ambornin-amsports:recode X 0=. 9=.
for var  prouddem-proudgrp:gen Xbin=X==1 if X~=.
egen uspridescal=rsum2(prouddembin-proudgrpbin),anymiss
for var ambornin-amfeel:gen Xbin=X==1 if X~=.
egen patriotscal=rsum2( amborninbin amcitbin amlivedbin amgovtbin amfeelbin),anymiss
for var  amcitizn-ifwrong:recode X 8=3
for var  amcitizn-ifwrong:gen Xbin=X<3 if X~=.
egen nationalistscal=rmean(amcitizn belikeus ambetter ifwrong)
replace nationalistscal=6-nationalistscal
recode educ 98/99=.
recode degree 8/9=.
recode  memnum -1=. 98/99=0
gen usaborn=born==1 
for var memfrat- memchurh:gen Xbin=X==1 if X>0&X~=.
gen south=reg16>4&region<8
recode memnum 1/2=1 3/100=2,g(memnumcat)
gen conservative=polviews==6|polviews==7 if polviews~=.
gen republican=if92who==2|if00who==2 if if92who~=.|if00who~=.
recode educ 0/6=1 7/11=2 12=3 13/15=4 16=5 17/19=6 20=7,g(educcat)
lab def educcat 1 "0-6 years" 2 "7-11 years" 3 "12 years" 4 "13-15 years" 5 "16 years" 6 "17/19 years" 7 "20+ years"
lab val educcat educcat
gen cohort=.
replace cohort=1996-age if year==1996
replace cohort=2004-age if year==2004
gen wtsum= wt2004+wt2004nr+wt7204
gen wtmult= wt2004*wt2004nr*wt7204
