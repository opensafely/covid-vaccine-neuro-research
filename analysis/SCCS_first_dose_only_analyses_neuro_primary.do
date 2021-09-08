/*==============================================================================
DO FILE NAME:			SCCS_first_dose_only_analyses_neuro_primary.do
PROJECT:				Vaccine Safety  
DATE: 					19th Aug 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS set up and SCCS primary analysis of neuro events - GBS, TM and BP
							
							

DATASETS USED:			input_AZ_cases.csv, input_PF_cases.csv, input_MOD_cases.csv
DATASETS CREATED: 		sccs_popn_BP_`brand'.dta, sccs_popn_TM_`brand'.dta, sccs_popn_GBS_`brand'.dta
						sccs_cutp_data_BP_`brand'.dta, sccs_cutp_data_TM_`brand'.dta, sccs_cutp_data_GBS_`brand'.dta
						(`brand' = AZ, PF, MOD)
						into /temp_data
OTHER OUTPUT: 			logfile, printed to folder /logs
						tables, printed to folder /tables
						
							
==============================================================================*/


/*
!CONSIDERATIONS BEFORE RUNNING!


those died within 28 days, etc. 

*/




/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"
capture	mkdir "`c(pwd)'/output/plots"
capture	mkdir "`c(pwd)'/output/tables"
capture	mkdir "`c(pwd)'/output/temp_data"

* set ado path
adopath + "`c(pwd)'/analysis/extra_ados"

*variable to cycle through each brand (AZ, PF, MOD)
local brand `1'

display "`brand'"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_first_dose_only_analyses_neuro_primary_`brand'.log", replace 


* IMPORT DATA=================================================================*/ 


clear

import delimited using `c(pwd)'/output/input_`brand'_cases.csv
gen first_brand="`brand'"

*checking first_brand variable
* these are listed for each doze as the input value is capitalised and variables are not 
assert first_az_date!="" if first_brand=="AZ"
assert first_moderna_date!="" if first_brand=="MOD"
assert first_pfizer_date!="" if first_brand=="PF"


*formatting dates
gen AZ_date=date(first_az_date,"DMY")
format AZ_date %td
gen PF_date=date(first_pfizer_date,"DMY")
format PF_date %td
gen MOD_date=date(first_moderna_date,"DMY")
format MOD_date %td


gen BP=any_bells_palsy
gen TM=any_transverse_myelitis
gen GBS=any_guillain_barre

foreach var of varlist second_any_vaccine_date second_pfizer_date second_az_date second_moderna_date BP TM GBS first_positive_covid_test{ 
						rename `var' _tmp
						gen `var' = date(_tmp, "YMD")
						drop _tmp
						format %d `var'
							
					   }

foreach var of varlist fu_cidp_gp fu_ms_no_gp { 
						rename `var' _tmp
						gen `var' = date(_tmp, "DMY")
						drop _tmp
						format %d `var'
							
					   }				   
					   
* create flag for first dose >=1st Jan for AZ PF comparison sensitivity analysis

gen incl_AZ_PF_compare=1 if (AZ_date>=d("01jan2021") & first_brand=="AZ") | (PF_date>=d("01jan2021") & first_brand=="PF")


*previous covid infection flag

gen prior_covid=1 if first_brand=="`brand'" & first_positive_covid_test < `brand'_date 


rename history_any_transverse_myelitis history_TM
rename history_any_bells_palsy history_BP
rename history_any_guillain_barre history_GBS


*create flag to drop if cidp date before gbs date
gen flag_X_before_GBS=1 if fu_cidp_gp <= GBS & GBS!=.


	
*create flag to drop TM if have MS/neuromyelitis_optica  before TM date
gen flag_X_before_TM=1 if fu_ms_no_gp<=TM & TM!=.


*nothing to drop before BP but need dummy flag for loop
gen flag_X_before_BP=. if BP!=.


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
gen vacc_date1= `brand'_date - study_start if first_brand=="`brand'"


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

preserve
keep patient_id age_group_SCCS first_brand incl_AZ_PF_compare hcw prior_covid

tempfile patient_info
save `patient_info', replace
restore


/*
**** Results output
tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str20(subanalysis) str15(category) str10(period) irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_primary_`brand'", replace
*/		
* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_primary_`brand'", replace
		


*loop over each outcome

foreach j of varlist BP TM GBS{

preserve
     
	 display "`j'"
	 
	 drop if flag_X_before_`j'==1
	 noi display "THIS MANY (ABOVE) HAVE X (CIDP for GBS, MS/NO for TM) DURING FU PRIOR TO GBS /TM SO DROPPED"
	 
	 
	 
	drop if history_`j'==1
	display "THIS MANY (ABOVE) HAVE HISTORY `j'"
	

	
	*only keep individuals who have at least one event
	keep if `j'!=.
	gen eventday=`j'-study_start
	
	

	
	*keep those indivs with events within follow up time
	
	display "THIS MANY HAVE EVENT PRIOR TO START FU `j'"
	drop if eventday<=start
	display "THIS MANY HAVE EVENT AFTER END FU `j'"
	drop if eventday>=end
	
	***ALSO DOUBLE CHECK HAVE VACCINE WITHIN FU TIME****
	drop if vacc_date1<=start
	drop if vacc_date1>=end
	
	
	*summary of length of follow up time
	display "SUMMARY OF FOLLOW UP TIME IN STUDY"
	summ cutp2, detail
	
	save "`c(pwd)'/output/temp_data/sccs_popn_`j'_`brand'.dta", replace
	
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
   
   	generate exgr2 = type-13 if type>=13 & type<=`w'
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
  
  save "`c(pwd)'/output/temp_data/sccs_cutp_data_`j'_`brand'.dta", replace
 
 *count how many outcomes there are on the day of vaccination
 display "NUMBER OF OUTCOMES ON DAY OF VACCINATION"
 display "`j'"
 count if nevents==1 & vacc1_`j'==2
 
 *count number of outcomes overall
 display "NUMBER OF OUTCOMES"
 display "`j'"
 count if nevents==1
 

 *summarise number of events by risk window
display "TABLE OF NUM EVENTS BY RISK WINDOW"
tabstat  nevents, s(sum) by(vacc1_`j')format(%9.0f)

*summarise number of events by week
display "TABLE OF NUM EVENTS BY WEEK"
tabstat  nevents, s(sum) by(week)format(%9.0f)
 
 
 
* Setup file for posting results
/*  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_primary_`brand'", replace
 
*/
 
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 
 
 xtpoisson nevents ib0.vacc1_`j', fe i(patient_id) offset(loginterval) eform

  if _rc==0{
  mat b = r(table) 
 

 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 
 else di "DID NOT CONVERGE - `brand' PRIMARY RISK WINDOW AFTER 1ST DOSE - NO PERIOD"
 
 display "add in week"
 
  xtpoisson nevents ib0.vacc1_`j' ib0.week , fe i(patient_id) offset(loginterval) eform
  
  
  if _rc==0{  
   mat b = r(table) 

 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 
 else di "DID NOT CONVERGE - `brand' PRIMARY RISK WINDOW AFTER 1ST DOSE - WEEK ADJ"
 
 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week, fe i(patient_id) offset(loginterval) eform
 
  if _rc==0{
  mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 else di "DID NOT CONVERGE - `brand' PRIMARY RISK WINDOW AFTER 1ST DOSE - 2 WEEK ADJ"
 

 restore
}
 
 
  * Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary_primary_`brand'", clear
export delimited using "`c(pwd)'/output/tables/results_summary_primary_`brand'.csv", replace

 




log close
