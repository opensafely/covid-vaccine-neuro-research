/*==============================================================================
DO FILE NAME:			SCCS_first_dose_only_analyses_neuro.do
PROJECT:				Vaccine Safety  
DATE: 					19th Aug 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS set up and analysis of vte events
							
							ADD MORE DESCRPTION OF MAIN VS SECONDARY ANALYSES

DATASETS USED:			input_az_cases.csv, input_pfizer_cases.csv and input_moderna_cases.csv
DATASETS CREATED: 		csvs as per project.yaml, into /tempdata
OTHER OUTPUT: 			logfile, printed to folder XXXX  TO BE ADDED
						tables, printer to folder XXXX   TO BE ADDED
						sccs_popn_BP.dta, sccs_popn_TM.dta, sccs_popn_GBS.dta
							
==============================================================================*/


/*
!CONSIDERATIONS BEFORE RUNNING!

**ADD THESE FROM NOTES!

those died within 28 days, etc. 

*/




/*STILL TO ADD


-code to export tables, etc.


*/


/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"
capture	mkdir "`c(pwd)'/output/plots"
capture	mkdir "`c(pwd)'/output/tables"
capture	mkdir "`c(pwd)'/output/temp_data"

* set ado path
adopath + "`c(pwd)'/analysis/extra_ados"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_first_dose_only_analyses.log", replace 



*append datasets for AZ and Pfizer first doses (easier to then do head to head comaprison sensitivity analysis)

*add variable for flag/separate analysis for Pfizer and AZ


* IMPORT DATA=================================================================*/ 


clear
import delimited `c(pwd)'/output/input_az_cases.csv
gen first_brand="AZ" 
tempfile az_first
save `az_first', replace

clear
import delimited `c(pwd)'/output/input_moderna_cases.csv
gen first_brand="MOD" 
tempfile mod_first
save `mod_first', replace


clear
import delimited `c(pwd)'/output/input_pfizer_cases.csv
gen first_brand="PF"
count

append using `az_first'
append using `mod_first'

*checking first_brand variable
assert first_az_date!="" if first_brand=="AZ"
assert first_moderna_date!="" if first_brand=="MOD"
assert first_pfizer_date!="" if first_brand=="PF"


*check no overlapping indivs
bysort patient_id: gen num=_n
assert num==1  /*need to extract new data for this to be correct */
drop num


*formatting dates
gen az_date=date(first_az_date,"DMY")
format az_date %td
gen pfizer_date=date(first_pfizer_date,"DMY")
format pfizer_date %td
gen moderna_date=date(first_moderna_date,"DMY")
format moderna_date %td


gen BP=any_bells_palsy
gen TM=any_transverse_myelitis
gen GBS=any_guillain_barre

foreach var of varlist second_any_vaccine_date second_pfizer_date second_az_date second_moderna_date BP TM GBS first_positive_covid_test{ 
						rename `var' _tmp
						gen `var' = date(_tmp, "YMD")
						drop _tmp
						format %d `var'
							
					   }

foreach var of varlist censor_date_bp censor_date_ms censor_date_gb{ 
						rename `var' _tmp
						gen `var' = date(_tmp, "DMY")
						drop _tmp
						format %d `var'
							
					   }
					   

					   

					   
					   
* create flag for first dose >=1st Jan for AZ PF comparison sensitivity analysis

gen incl_AZ_PF_compare=1 if (az_date>=d("01jan2021") & first_brand=="AZ") | (pfizer_date>=d("01jan2021") & first_brand=="PF")


*previous covid infection flag

gen prior_covid=1 if first_brand=="AZ" & first_positive_covid_test < az_date 
replace prior_covid=1 if first_brand=="MOD" & first_positive_covid_test < moderna_date 
replace prior_covid=1 if first_brand=="PF" & first_positive_covid_test < pfizer_date 






*define age group so can explore for effect modification by age (18-39, 40-64, 65-105)

datacheck age>=18 & age <=105, nolist   


*AGE GROUPS FOR STRATIFICATION
gen age_group_SCCS="18-39" if age>=18 & age<=39
replace age_group_SCCS="40-64" if age>=40 & age<=64
replace age_group_SCCS="65-105" if age>=65 & age<=105



* make days from 1st Jul 2020 baseline (rather than usual age- age doesn't change over the study)

*create intervals using study start date as baseline

gen study_start= date("01/07/2020","DMY")
gen study_end= date(censor_date,"DMY")
format study_start %td
format study_end %td


gen start=0
gen end=study_end-study_start

*days since start of study, indiv had first vaccination date 
gen vacc_date1= az_date - study_start if first_brand=="AZ"
replace vacc_date1= pfizer_date - study_start if first_brand=="PF"
replace vacc_date1= moderna_date - study_start if first_brand=="MOD"


*generate cut points that event will lie between

gen cutp1=start
gen cutp2=end




*cutpoints for risk windows
*want -28 (TM or GBS) / -14 (BP) days removed in primary for healthy vaccinee bias
* main window 4-28 days inclusive (BP or TM), 4-42 days (GBS)
* sens windows 4-7, 8-14,15-28 (29-42 for GBS)
*extended risk windows 4-42 days (BP or TM), 4-90 days (GBS)

gen cutp3=vacc_date1-29
gen cutp4=vacc_date1-15
gen cutp5=vacc_date1-1
gen cutp6=vacc_date1-0
gen cutp7=vacc_date1+3
gen cutp8=vacc_date1+7
gen cutp9=vacc_date1+14
gen cutp10=vacc_date1+28
gen cutp11=vacc_date1+42
gen cutp12=vacc_date1+90



*add in weekly time period in case we need it
*put extra bit of week in with last week


egen test=max(end)
gen test2=floor(test/7) +12
local n=test2[1]
display `n'
display "weeks"
foreach i of numlist 13/`n' {
 display `i'
 gen cutp`i' = (`i'-2)*7
 }

local last=`n'+1
display `last'
gen cutp`last'=cutp2
  *any remaining time up to end of study period (just to double check)


*** CENSOR CUT-POINTS AT START OR END OF FOLLOW UP
foreach var of varlist cutp*{
replace `var' = cutp1 if `var' < cutp1
replace `var' = cutp2 if `var' > cutp2
}	



*keep variables in overall dataset we want to adjust for/ exclude in sensitivity analyses
*to merge back on once have cut up the data into time intervals and collapsed

*anything else to adjust for /exclude in sensitivity analyses?

preserve
keep patient_id age_group_SCCS first_brand incl_AZ_PF_compare hcw prior_covid

tempfile patient_info
save `patient_info', replace
restore

*rename so fits in with loop names for outcomes already made
rename censor_date_bp censor_date_BP 
rename censor_date_ms censor_date_TM
rename censor_date_gb censor_date_GBS


**** Results output
tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str20(subanalysis) str15(category) str10(period) irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary", replace
		


*loop over each outcome

foreach j in BP TM GBS{

preserve
    
	**UPDATE END (CUTP2) BASED ON CENSOR DATE SPECIFIC TO EACH OUTCOME ***
	**EG. IF HAVE  EVENT PRIOR TO OUTCOME, DON'T COUNT OUTCOME (SEE PROTOCOL)
	gen censor_day=censor_date_`j'-study_start
	replace end=min(end,censor_day) if censor_day!=.
	
	display "THIS MANY (ABOVE) HAVE EVENT PRIOR TO OUTCOME SO CENSORED/DROPPED"
	
	
	*only keep individuals who have at least one event
	keep if `j'!=.
	gen eventday=`j'-study_start
	
	
	*keep those indivs with events within follow up time
	drop if eventday<=start
	drop if eventday>=end
	
	***ALSO DOUBLE CHECK HAVE VACCINE WITHIN FU TIME****
	drop if vacc_date1<=start
	drop if vacc_date1>=end
	
	save "`c(pwd)'/output/temp_data/sccs_popn_`j'.dta", replace
	
*** now reshape and collapse
compress

sort patient_id eventday
reshape long cutp, i(patient_id eventday) j(type)
sort patient_id eventday cutp type

*number of adverse events within each interval
by patient_id: generate int nevents = 1 if eventday > cutp[_n-1]+0.5 & eventday <= cutp[_n]+0.5
collapse (sum) nevents, by(patient_id cutp type)

*intervals
by patient_id: generate int interval = cutp[_n] - cutp[_n-1]
	
	
	*vaccine exposure groups
	
	generate exgr1 = type-3 if type>=3 & type<=12
		count if exgr1 >=.
		local nmiss = r(N)
		local nchange = 1
		while `nchange'>0{
		by patient_id: replace exgr1 = exgr1[_n+1] if exgr1>=.
		count if exgr1>=.
		local nchange = `nmiss'-r(N)
		local nmiss = r(N)
			}
	replace exgr1 = 0 if exgr1==.
	
	*1. create variables for main analyses risk windows for BP, TM and for GBS
		*BP
		recode exgr1 (0=0) (1=0) (2=1) (3=2) (4=3) (5=4) (6=4) (7=4) (8=0) (9=0), generate(vacc1_BP)
			** vacc1_BP has 5 levels, non-risk (0), pre-vacc low 14 days (1), day 0 (2) days 1-3 (3), days 4-28 (4) 
			label define vacc1_BP1 0 "non-risk" 1 "pre-vacc 14" 2 "day 0" 3 "days 1-3" 4 "days 4-28" 
			label values vacc1_BP vacc1_BP1	
	
		*TM
		recode exgr1 (0=0) (1=1) (2=1) (3=2) (4=3) (5=4) (6=4) (7=4) (8=0) (9=0), generate(vacc1_TM)
			** vacc1_TM has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-28 (4) 
			label define vacc1_TM1 0 "non-risk" 1 "pre-vacc 28" 2 "day 0" 3 "days 1-3" 4 "days 4-28" 
			label values vacc1_TM vacc1_TM1
   
		*GBS
		recode exgr1 (0=0) (1=1) (2=1) (3=2) (4=3) (5=4) (6=4) (7=4) (8=4) (9=0), generate(vacc1_GBS)
			** vacc1_GBS has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-42 (4)
			label define vacc1_GBS1 0 "non-risk" 1 "pre-vacc 28" 2 "day 0" 3 "days 1-3" 4 "days 4-42" 
			label values vacc1_GBS vacc1_GBS1
	
	*2. create variables for risk windows broken down for BP & TM, and for GBS
		*BP
		recode exgr1 (0=0) (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=0) (9=0), generate(vacc1_BP_sep)
			** vacc1_BP_sep has 7 levels, non-risk (0), pre-vacc low 14 days (1), day 0 (2) days 1-3 (3), days 4-7 (4), days 8-14 (5), days 15-28 (6)
			label define vacc1_BP_sep1 0 "non-risk" 1 "pre-vacc 14" 2 "day 0" 3 "days 1-3" 4 "days 4-7" 5 "days 8-14" 6 "days 15-28"
			label values vacc1_BP_sep vacc1_BP_sep1
		*TM
		recode exgr1 (0=0) (1=1) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=0) (9=0), generate(vacc1_TM_sep)
			** vacc1_TM_sep has 7 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-7 (4), days 8-14 (5), days 15-28 (6)
			label define vacc1_TM_sep1 0 "non-risk" 1 "pre-vacc 28" 2 "day 0" 3 "days 1-3" 4 "days 4-7" 5 "days 8-14" 6 "days 15-28"
			label values vacc1_TM_sep vacc1_TM_sep1
			
		*GBS	
		recode exgr1 (0=0) (1=1) (2=1) (3=2) (4=3) (5=4) (6=5) (7=6) (8=7) (9=0), generate(vacc1_GBS_sep)
			** vacc1_GBS_sep has 8 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-7 (4), days 8-14 (5), days 15-28 (6), days 29-42 (7)
			label define vacc1_GBS_sep1 0 "non-risk" 1 "pre-vacc 28" 2 "day 0" 3 "days 1-3" 4 "days 4-7" 5 "days 8-14" 6 "days 15-28" 7 "days 29-42"
			label values vacc1_GBS_sep vacc1_GBS_sep1
		
			
	*3. create variables for excluding 28 day period pre vaccination
		*BP
		recode exgr1 (0=0) (1=0) (2=0) (3=1) (4=2) (5=3) (6=3) (7=3) (8=0) (9=0), generate(vacc1_BP_nopre)
			** vacc1_BP_nopre has 4 levels, non-risk (0), day 0 (1) days 1-3 (2), days 4-28 (3) 
			label define vacc1_BP_nopre1 0 "non-risk" 1 "day 0" 2 "days 1-3" 3 "days 4-28" 
			label values vacc1_BP_nopre vacc1_BP_nopre1	
	
		*TM
		recode exgr1 (0=0) (1=0) (2=0) (3=1) (4=2) (5=3) (6=3) (7=3) (8=0) (9=0), generate(vacc1_TM_nopre)
			** vacc1_TM_nopre has 4 levels, non-risk (0), day 0 (1) days 1-3 (2), days 4-28 (3) 
			label define vacc1_TM_nopre1 0 "non-risk"  1 "day 0" 2 "days 1-3" 3 "days 4-28" 
			label values vacc1_TM_nopre vacc1_TM_nopre1
   
		*GBS
		recode exgr1 (0=0) (1=0) (2=0) (3=1) (4=2) (5=3) (6=3) (7=3) (8=3) (9=0), generate(vacc1_GBS_nopre)
			** vacc1_GBS_nopre has 4 levels, non-risk (0), day 0 (1) days 1-3 (2), days 4-42 (3)
			label define vacc1_GBS_nopre1 0 "non-risk" 1 "day 0" 2 "days 1-3" 3 "days 4-42" 
			label values vacc1_GBS_nopre vacc1_GBS_nopre1	
	
	
	
	*4. create variables for extended risk periods
		*BP
		recode exgr1 (0=0) (1=0) (2=1) (3=2) (4=3) (5=4) (6=4) (7=4) (8=4) (9=0), generate(vacc1_BP_ext)
			** vacc1_BP_ext has 5 levels, non-risk (0), pre-vacc low 14 days (1), day 0 (2) days 1-3 (3), days 4-42 (4) 
			label define vacc1_BP_ext1 0 "non-risk" 1 "pre-vacc 14" 2 "day 0" 3 "days 1-3" 4 "days 4-42" 
			label values vacc1_BP_ext vacc1_BP_ext1	
	
		*TM
		recode exgr1 (0=0) (1=1) (2=1) (3=2) (4=3) (5=4) (6=4) (7=4) (8=4) (9=0), generate(vacc1_TM_ext)
			** vacc1_TM_ext has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-42 (4) 
			label define vacc1_TM_ext1 0 "non-risk" 1 "pre-vacc 28" 2 "day 0" 3 "days 1-3" 4 "days 4-42" 
			label values vacc1_TM_ext vacc1_TM_ext1
   
		*GBS
		recode exgr1 (0=0) (1=1) (2=1) (3=2) (4=3) (5=4) (6=4) (7=4) (8=4) (9=4), generate(vacc1_GBS_ext)
			** vacc1_GBS_ext has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-90 (4)
			label define vacc1_GBS_ext1 0 "non-risk" 1 "pre-vacc 28" 2 "day 0" 3 "days 1-3" 4 "days 4-90" 
			label values vacc1_GBS_ext vacc1_GBS_ext1	

   
   *weekly exposure groups
   
   *up to maximum cutp for weeks defined by max length of study_end
   
   egen test3=max(type)
   local w=test3[1]
   
   	generate exgr2 = type-3 if type>=3 & type<=`w'
		count if exgr2 >=.
		local nmiss = r(N)
		local nchange = 1
		while `nchange'>0{
		by patient_id: replace exgr2 = exgr2[_n+1] if exgr2>=.
		count if exgr2>=.
		local nchange = `nmiss'-r(N)
		local nmiss = r(N)
			}
	replace exgr2 = 0 if exgr2==.   /*check this doesn't apply to those in last week group */
	
	*create weekly and 2 weekly
	
	gen week=exgr2
	
	gen two_week=floor(week/2)
	
	*think this works? previous code for 2 weekly variable...
   	/*recode exgr2 (0=0) (1=0) (2=1) (3=1) (4=2) (5=2) (6=3) (7=3) (8=4) (9=4) (10=5) (11=5) (12=6) (13=6) (14=7) (15=7) (16=8) ///
	 (17=8) (18=9) (19=9) (20=10) (21=10) (22=11) (23=11) (24=12) (25=12) (26=13) (27=13) (28=14) (29=14) (30=15) (31=15) (32=16) (33=16) (34=17) (35=17),generate(two_week) */
   
  
   
   
   
drop cutp* type
drop if interval ==0 | interval==.

generate loginterval = log(interval)
   
 
 
 
 
 *add back in agegroup (age_group_SCCS), 
 *vaccine brand info (first_brand)
 *flag for first dose >=1st Jan for AZ PF comparison (incl_AZ_PF_compare)
 *hcw
 *history of covid infection
 
 merge m:1 patient_id using `patient_info'
 keep if _merge==3
 drop _merge
  
  
 
 *count how many outcomes there are on the day of vaccination
 display "NUMBER OF OUTCOMES ON DAY OF VACCINATION"
 display "`j'"
 count if nevents==1 & vacc1_`j'==2
 
* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary", replace
 
 foreach brand in AZ PF MOD{
 
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 
 
 xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform

 
  mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "add in week"
 
  xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
  
   mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
  mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 

 
 *stratify by age
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
 display "STRATIFIED BY AGE"
  *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 

 display "AGE=18-39"
 xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'" & age_group_SCCS=="18-39", fe i(patient_id) offset(loginterval) eform
 
  mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("18-39") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "AGE=40-64"
 xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'" & age_group_SCCS=="40-64", fe i(patient_id) offset(loginterval) eform
 
   mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("40-64") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 
 display "AGE=65-105"
 xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'" & age_group_SCCS=="65-105", fe i(patient_id) offset(loginterval) eform
 
   mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("65-105") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 
 display "ADD IN WEEK PERIOD"
 
  display "AGE=18-39"
  xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'" & age_group_SCCS=="18-39", fe i(patient_id) offset(loginterval) eform
  
    mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("18-39") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
  display "AGE=40-64"
  xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'" & age_group_SCCS=="40-64", fe i(patient_id) offset(loginterval) eform
  
   mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("40-64") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
  display "AGE=65-105"
  xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'" & age_group_SCCS=="65-105", fe i(patient_id) offset(loginterval) eform
  
   mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("65-105") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "ADD IN 2 WEEK PERIOD"
 
 display "AGE=18-39"
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'" & age_group=="18-39", fe i(patient_id) offset(loginterval) eform
 
     mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("18-39") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "AGE=40-64"
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'" & age_group=="40-64", fe i(patient_id) offset(loginterval) eform
  
     mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("40-64") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 
 display "AGE=65-105"
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'" & age_group=="65-105", fe i(patient_id) offset(loginterval) eform
  
     mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("65-105") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 
 *exclude healthcare workers
  display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
 display "EXCLUDING HEALTHCARE WORKERS"
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 
 
 xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'" & hcw==0, fe i(patient_id) offset(loginterval) eform
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 
 mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("exclude hcw") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "add in week"
 
  xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'" & hcw==0, fe i(patient_id) offset(loginterval) eform
  
   mat b = r(table) 
 
   forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("exclude hcw") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'" & hcw==0, fe i(patient_id) offset(loginterval) eform
 
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("exclude hcw") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 
 
 
 **previous COVID infection
   display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
 display "STRATIFIED BY PREVIOUS COVID INFECTION (PRIOR TO FIRST VACCINE DATE)"
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 
 display "prior covid"
 xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'" & prior_covid==1, fe i(patient_id) offset(loginterval) eform
 
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("prior covid") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	
 display "no prior covid"
 xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'" & prior_covid!=1, fe i(patient_id) offset(loginterval) eform
 
  
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("no prior covid") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 display "add in week"
 display "prior covid"
 xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'" & prior_covid==1, fe i(patient_id) offset(loginterval) eform
 
  
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("prior covid") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	
 display "no prior covid"
 xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'" & prior_covid!=1, fe i(patient_id) offset(loginterval) eform
 
  
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("no prior covid") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 display "add in 2 week period"
 display "prior covid"
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'" & prior_covid==1, fe i(patient_id) offset(loginterval) eform
 
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("prior covid") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	
 display "no prior covid"
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'" & prior_covid!=1, fe i(patient_id) offset(loginterval) eform
 
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("no prior covid") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 

 
 
 
 
 *broken down risk windows
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
 display "BROKEN DOWN INTERVALS"
** vacc1_BP_sep has 7 levels, non-risk (0), pre-vacc low 14 days (1), day 0 (2) days 1-3 (3), days 4-7 (4), days 8-14 (5), days 15-28 (6)
** vacc1_TM_sep has 7 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-7 (4), days 8-14 (5), days 15-28 (6)
** vacc1_GBS_sep has 8 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-7 (4), days 8-14 (5), days 15-28 (6), days 29-42 (7)	
 
 
 if "`j" == "GBS" {
 local levels = 8
 }
 else {
 local levels = 7
 }
 
 xtpoisson nevents ib0.vacc1_`j'_sep  if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
   mat b = r(table) 
 
  forvalues v = 1/`levels' {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("broken down levels") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}

 display "add in week"
 
 xtpoisson nevents ib0.vacc1_`j'_sep ib0.week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
    mat b = r(table) 
 
  forvalues v = 1/`levels' {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("broken down levels") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}


 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j'_sep ib0.two_week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform

    mat b = r(table) 
 
  forvalues v = 1/`levels' {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("broken down levels") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}

 
 

 *exclude pre-vacc period
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
 display "EXCLUDE/DON'T REMOVE PRE_VACCINATION PERIOD"
 ** vacc1_BP_nopre has 4 levels, non-risk (0), day 0 (1) days 1-3 (2), days 4-28 (3) 
** vacc1_TM_nopre has 4 levels, non-risk (0), day 0 (1) days 1-3 (2), days 4-28 (3)
** vacc1_GBS_nopre has 4 levels, non-risk (0), day 0 (1) days 1-3 (2), days 4-42 (3)	
 
 xtpoisson nevents ib0.vacc1_`j'_nopre  if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
  
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("don't rm prevac period") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 

 display "add in week"
 
 xtpoisson nevents ib0.vacc1_`j'_nopre ib0.week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform

    mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("don't rm prevac period") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 

 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j'_nopre ib0.two_week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
    mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("don't rm prevac period") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 

 
 
 
 *extended risk window
  display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' EXTENDED RISK WINDOW AFTER 1ST DOSE"
** vacc1_BP_ext has 5 levels, non-risk (0), pre-vacc low 14 days (1), day 0 (2) days 1-3 (3), days 4-42 (4) 	
** vacc1_TM_ext has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-42 (4) 
** vacc1_GBS_ext has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-90 (4)  

 xtpoisson nevents ib0.vacc1_`j'_ext if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
    mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Extended risk window after 1d") ("") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 display "add in week"
 
 xtpoisson nevents ib0.vacc1_`j'_ext ib0.week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
     mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Extended risk window after 1d") ("add in week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j'_ext ib0.two_week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
      mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Extended risk window after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 }
 *head to head comparison- AZ vs PF
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "AZ VS PF PRIMARY RISK WINDOW AFTER 1ST DOSE"
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 
 *only want comparision of AZ to PF
 drop if first_brand=="MOD"
 
 
 **IF DOSES >1JAN  (incl_AZ_PF_compare==1)!!
 
 *need originals to comapre to limited to >1st Jan as well
 xtpoisson nevents ib0.vacc1_`j' if first_brand=="AZ" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("") ("First = AZ") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 xtpoisson nevents ib0.vacc1_`j' if first_brand=="PF" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
  
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("") ("First = PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 *xtpoisson nevents ib0.vacc1_`j'##first_brand if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform

 
 display "add in week"
 
 xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="AZ" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
  
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in week") ("First = AZ") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	
 xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="PF" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in week") ("First = PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 * xtpoisson nevents ib0.vacc1_`j'##first_brand ib0.week##first_brand if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="AZ" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in 2 week") ("First = AZ") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="PF" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in 2 week") ("First = PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 *xtpoisson nevents ib0.vacc1_`j'##first_brand ib0.two_week##first_brand if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 *
 
 
 
 
 
 
 
 


 * add in code to extract for tables
 
 restore
 
 }
 
 
 


*loop over
     *decide what doing with those who died within 28 days of VTE (depending on numbers from descriptive bit)	 

* AZ dose 1 and outcome 1,2,..
* Pfizer dose 1 and outcome 1,2,...
* different windows
/*
exposed 4-28 days, broken down into windows


when don't drop 28 day window pre-vaccination --> histograms as per protocol


*/

*explore effect modification by age group (16-39, 40-64, 65+)

*explore for time-varying confounding by time-updated hospital admission status

*sens - exclude healthcare workers
     *- unspecified or different brand of vaccine to first dose - depending on numbers censor on 2nd dose

	 
	 
*and then second doses
*compare AZ to PF- limited to vaccinations >= 1st Jan 2021


* Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary", clear
export delimited using "`c(pwd)'/output/tables/results_summary.csv", replace


log close
