use BORN PROUD* AMPROUD* AMBORNIN AMCIT AMLIVED AMENGLSH AMCHRSTN AMGOVT AMFEEL AMCITIZN AMSHAMED BELIKEUS AMBETTER IFWRONG AMSPORTS EDUC DEGREE AGE PAEDUC MAEDUC PADEG MADEG PAOCC80 MAOCC80 PASEI MASEI OCC80 SEI PRESTG80 WRKSTAT SEX RACE MEM* MEMNUM YEAR WT* OVER* REGION REG16 INCOME98 RINCOM98 WKSUP WKSUPS POLVIEWS VOTE* using "C:\DATA\GSS\gss-cumulative-1972-2006.dta", clear

foreach v of varlist _all {
	ren `v' `=lower("`v'")'
	}
	
do "N:\Private\patriotism-choice-process\patriotism-dataproc.do"

cap drop _*
tempvar x2 p b
qui gen `x2'=.
qui gen `p'=.
qui gen `b'=.
local i=1
foreach v of varlist prouddembin-proudgrpbin {
	quietly {
		xi:logit `v' i.year cohort [iw=wt2004+wt2004nr+wt7204]
		mat B=e(b)
		replace `b'=exp(B[1,1]) in `i'
		test _Iyear_2004
		replace `x2'=r(chi2) in `i'
		replace `p'=r(p) in `i'
		local i=`i'+1
		}
	}
format `p' %9.4f
format `b' `x2' %9.2f
list `b' `x2' `p' in 1/10,clean 

table year [aw=wt2004+wt2004nr+wt7204],c(mean uspridescal) format(%9.2f)


table educcat year [aw=wt2004+wt2004nr+wt7204],c(mean uspridescal) format(%9.2f)

est drop _all
quietly {
	eststo:xi3: regress uspridescal educcat cohort if year==1996 [aw=wt2004+wt2004nr+wt7204] 
	est store mod1
	eststo:xi3: regress uspridescal educcat cohort if year==2004  [aw=wt2004+wt2004nr+wt7204] 
	est store mod2
	}
esttab

est drop _all
quietly {
	eststo:xi3: regress uspridescal sei cohort if year==1996 [aw=wt2004+wt2004nr+wt7204] 
	est store mod1
	eststo:xi3: regress uspridescal sei cohort if year==2004  [aw=wt2004+wt2004nr+wt7204] 
	est store mod2
	}
esttab

est drop _all
quietly {
	eststo:xi3: regress uspridescal nationalistscal cohort if year==1996 [aw=wt2004+wt2004nr+wt7204] 
	est store mod1
	eststo:xi3: regress uspridescal nationalistscal cohort if year==2004  [aw=wt2004+wt2004nr+wt7204] 
	est store mod2
	}
esttab

cap drop adjdegre* diff
gen diff=.
qui xi3:regress uspridescal educcat*i.year cohort[aw=wt2004+wt2004nr+wt7204]
postgr3 educcat,by(year) gen(adjdegree) 
qui levelsof educcat,l(deglevs)
foreach l of local deglevs {
	qui sum adjdegree2004 if educcat==`l'
	local m2=r(mean)
	qui sum adjdegree1996 if educcat==`l'
	local m1=r(mean)
	qui replace diff=`m2'-`m1' if educcat==`l'
	}
tabstat adjdegree1996 adjdegree2004 diff,by(educcat)

center educ
est drop _all
quietly {
	eststo:xi3:regress uspridescal c_educ*i.year cohort [aw=wt2004+wt2004nr+wt7204]
	est store mod1
	*eststo:xi3:regress patriotscal c_educ*i.year cohort [aw=wt2004+wt2004nr+wt7204]
	*est store mod2
	eststo:xi3:regress nationalistscal c_educ*i.year cohort [aw=wt2004+wt2004nr+wt7204]
	est store mod3
	}
esttab




set scheme s1color
graph box uspridescal [pw=wtmult],over(year)  ///
ytitle("U.S. Pride Scale Score") ///
ylab(0(1)10) cwhiskers capsize(5) 

foreach v of varlist  proudmilbin   proudhisbin   proudartbin proudsptbin proudecobin {
	table year [aw=wtmult],c(mean `v')
	}
	





est drop _all
quietly {
	eststo:xi3: regress uspridescal  educ cohort i.sex i.race  south if year==2004  [aw= wt2004+wt2004nr+wt7204] 
	eststo:xi3: regress uspridescal  educ cohort i.sex i.race  south nationalistscal if year==2004  [aw= wt2004+wt2004nr+wt7204] 
	eststo:xi3: regress uspridescal  educ cohort i.sex i.race  south i.memnumcat  if year==2004 [aw= wt2004+wt2004nr+wt7204]   
	eststo:xi3: regress uspridescal  educ cohort i.sex i.race  south i.memnumcat nationalistscal  if year==2004 [aw= wt2004+wt2004nr+wt7204]   
	}
esttab


gen uspridescal2=uspridescal-proudmilbin
gen lab=_n in 1/15
cap lab drop meme
lab def mem 1 "Fraternal" 2 "Service" 3 "Veteran" 4 "Political Club" 5 "Labor Union" 6 "Sports Club" 7 "Youth Group" 8 "School Service" 9 "Hobby Club" 10 "School Fraternity" 11 "Nationality Group" 12 "Farm Organization" 13 "Literary or Art" 14 "Professional Society" 15 "Church"
lab val lab mem

tempvar b lo hi 
qui gen `b'=.
qui gen `lo'=.
qui gen `hi'=.
local i=1
foreach v of varlist memfratbin-memchurhbin {
	qui regress uspridescal `v' cohort [pw=wt2004+wt2004nr+wt720]
	mat B=e(b)
	mat V=e(V)
	qui replace `b'=B[1,1] in `i'
	qui replace `lo'=B[1,1]-(sqrt(V[1,1])*1.96) in `i'
	qui replace `hi'=B[1,1]+(sqrt(V[1,1])*1.96) in `i'
	replace lab=`i' in `i'
	local i=`i'+1
	}
format `b' `lo' `hi' %9.2f
list lab `lo'  `b' `hi' in 1/15,clean 
