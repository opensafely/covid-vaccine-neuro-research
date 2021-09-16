/*==============================================================================
DO FILE NAME:			SCCS_first_second_dose_only_analyses_neuro.do
PROJECT:				Vaccine Safety  
DATE: 					19th Aug 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS analysis of first and second doses
							
							

DATASETS USED:			input_AZ_cases.csv, input_PF_cases.csv and input_MOD_cases.csv
DATASETS CREATED: 		csvs as per project.yaml, into /tempdata
OTHER OUTPUT: 			logfile, `c(pwd)'/output/logs/SCCS_first_second_dose_analyses_`brand' (brand=AZ, PF, MOD)
						tables, printed to folder `c(pwd)'/output/tables  TO BE ADDED
						"`c(pwd)'/output/temp_data/sccs_popn_2doses_`j'_`brand'.dta" (j outcome BP, TM, GBS)
							
==============================================================================*/


/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"

capture	mkdir "`c(pwd)'/output/tables"
capture	mkdir "`c(pwd)'/output/temp_data"

* set ado path
adopath + "$projectdir/analysis/extra_ados"

*variable to cycle through each brand (AZ, PF, MOD)
local brand "AZ"
display "`brand'"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_first_second_dose_analyses_neuro_`brand'.log", replace 

* IMPORT DATA=================================================================*/ 
clear
import delimited using `c(pwd)'/output/input_`brand'_cases.csv

* ANALYSIS====================================================================*/ 

gen first_brand="`brand'"

*checking first_brand variable
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
*check ages ok
datacheck age>=18 & age <=105, nolist   

rename history_any_transverse_myelitis history_TM
rename history_any_bells_palsy history_BP
rename history_any_guillain_barre history_GBS

*create flag to drop if cidp date before gbs date
gen flag_X_before_GBS=1 if fu_cidp_gp <= GBS & GBS!=.

*create flag to drop TM if have MS/neuromyelitis_optica  before TM date
gen flag_X_before_TM=1 if fu_ms_no_gp<=TM & TM!=.

*nothing to drop before BP but need dummy flag for loop
gen flag_X_before_BP=. if BP!=.

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

*SECOND DOSES
*count and create flag (to censor) for more than one brand given on same date for second dose
noi di "COUNT IF 2nd DOSE AZ AND PFIZER ON SAME DATE"
count if second_pfizer_date == second_az_date & second_az_date!=. & (first_brand=="AZ" | first_brand=="PF")
gen censor_fu_dose2=1 if second_pfizer_date == second_az_date & second_az_date!=. & (first_brand=="AZ" | first_brand=="PF")

noi di "COUNT IF 2nd DOSE AZ AND MODERNA ON SAME DATE"
count if second_az_date == second_moderna_date & second_az_date != . & (first_brand=="AZ" | first_brand=="MOD")
replace censor_fu_dose2=1 if second_az_date == second_moderna_date & second_az_date != . & (first_brand=="AZ" | first_brand=="MOD")

noi di "COUNT IF 2nd DOSE PFIZER AND MODERNA ON SAME DATE"
count if second_pfizer_date == second_moderna_date & second_pfizer_date != .  & (first_brand=="PF" | first_brand=="MOD")
replace censor_fu_dose2=1 if second_pfizer_date == second_moderna_date & second_pfizer_date != . & (first_brand=="PF" | first_brand=="MOD")

gen end_date_dose2=min(second_az_date, second_pfizer_date, second_moderna_date) if censor_fu_dose2==1

*also need to censor at second dose brand different to first
*count and create flags for when second dose brand is different to first

 noi di "COUNT OF 2ND DOSE BRAND DIFFERENT TO 1ST DOSE BRAND (`brand')"

 display "AZ"
 count if ((first_brand=="AZ" & second_pfizer_date!=.) | (first_brand=="AZ" & second_moderna_date!=.)) 
 display "PF"
 count if ((first_brand=="PF" & second_az_date!=.) | (first_brand=="PF" & second_moderna_date!=.)) 
 display "MOD"
 count if ((first_brand=="MOD" & second_pfizer_date!=.) | (first_brand=="MOD" & second_az_date!=.)) 
 
gen censor_fu_diff_brand2=1 if ((first_brand=="AZ" & second_pfizer_date!=.) | (first_brand=="AZ" & second_moderna_date!=.)) 
replace censor_fu_diff_brand2=1 if ((first_brand=="PF" & second_az_date!=.) | (first_brand=="PF" & second_moderna_date!=.)) 
replace censor_fu_diff_brand2=1 if ((first_brand=="MOD" & second_pfizer_date!=.) | (first_brand=="MOD" & second_az_date!=.)) 

*may be some overlap with censor_fu_diff_brand2 and censor_fu_dose2
noi di "COUNT IF 2nd DOSE DIFFERENT TO 1st AND NOT 2 DIFFERENT ON SAME DAY 2ND DOSE"
noi di "1st DOSE = `brand'"
count if censor_fu_diff_brand2==1 & censor_fu_dose2!=1 

*if second dose unspecified- assume the same as first
gen unspec_second_dose=1 if second_any_vaccine_date!=. & second_az_date==. & second_pfizer_date==. & second_moderna_date==.
noi di "COUNT IF SECOND DOSE IS UNSPECIFIED"
count if unspec_second_dose==1

replace second_az_date=second_any_vaccine_date if second_az_date==. & unspec_second_dose==1 & first_brand=="AZ"
display "THIS MANY (ABOVE) UNSPEC SECOND DOSE BUT AZ FIRST"

replace second_pfizer_date=second_any_vaccine_date if second_pfizer_date==. & unspec_second_dose==1 & first_brand=="PF"
display "THIS MANY (ABOVE) UNSPEC SECOND DOSE BUT PF FIRST"

replace second_moderna_date=second_any_vaccine_date if second_moderna_date==. & unspec_second_dose==1 & first_brand=="MOD"
display "THIS MANY (ABOVE) UNSPEC SECOND DOSE BUT PF FIRST"

*flag to include 2nd dose if not 2 different on same day, not different brand to 1st...
gen incl_2nd_dose_`brand'=1 if censor_fu_diff_brand2!=1 & censor_fu_dose2!=1 & first_brand=="`brand'"

*second doses
*replace end date = censor date if 2 different brands on vaccine 2nd dose on same day, or 2nd dose brand different to first
replace end= end_date_dose2 - study_start if censor_fu_dose2==1 
replace end= second_any_vaccine_date - study_start if censor_fu_diff_brand2==1

*there will only be one date in any of the second dose varaibles, i.e. same date in second_az_date and second_any_vaccine_date if second dose is AZ and no other vaccines recieved 
rename second_az_date second_AZ_date
rename second_pfizer_date second_PF_date
rename second_moderna_date second_MOD_date

*time since study start of dose 2
gen vacc_date2= second_`brand'_date - study_start if incl_2nd_dose_`brand'==1 & second_`brand'_date!=.
gen vacc2=1 & (vacc_date2!=.) & vacc_date2 <= end 

di "THIS MANY HAD A VALID SECOND DOSE DURING THE FU"
tab vacc2, m 

replace vacc_date2=99999999 if vacc_date2==.
*this is outwith the study period

*generate cut points that event will lie between

gen cutp1=start
gen cutp2=end

*cutpoints for risk windows
*want -28 (TM or GBS) / -14 (BP) days removed in primary for healthy vaccinee bias
* main window 4-28 days inclusive (BP or TM), 4-42 days (GBS)

*ASSERT >=21 days between doses
datacheck vacc_date2- vacc_date1 >=21 if vacc_date2!=., nolist

* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_second_doses_`brand'", replace
		
foreach j in BP TM GBS{

	preserve

	gen outcome="`j'"

	gen cutp3=vacc_date1-29 if outcome=="GBS" | outcome=="TM"
	replace cutp3= vacc_date1-15 if outcome=="BP"
	gen cutp4=vacc_date1-1  
	gen cutp5=vacc_date1-0
	gen cutp6=vacc_date1+3
	gen cutp7=vacc_date1+28 if outcome=="BP" | outcome=="TM"
	replace cutp7=vacc_date1+42 if outcome=="GBS"

	*risk windows for second dose 4-42 days 
	gen cutp8=vacc_date2-29 if outcome=="GBS" | outcome=="TM"
	replace cutp8=vacc_date2-15 if outcome=="BP"
	gen cutp9=vacc_date2-1
	gen cutp10=vacc_date2-0
	gen cutp11=vacc_date2+3
	gen cutp12=vacc_date2+28 if outcome=="BP" | outcome=="TM"
	replace cutp12=vacc_date2+42 if outcome=="GBS"

	*need to consider that risk window after dose 1 is censored at vacc date2 +4 days for GBS and TM, larger overlap for BP

	*** for those with risk window after dose 1 overlapping with day 4-42 after dose 2, censor risk window post dose 1 at dose 2 +4 days which is the start of the dose 2 risk window
	* end dose 1 risk window at start of dose 2 risk window (dose 2 risk trumps dose 1 risk)
	replace cutp7= min(cutp7, cutp11) if vacc_date2!=.

	*if cutp7 >= cutp11 (i.e. risk windows overlap) then don't need cutp8-11 (dose 2 pre-vacc, dose 2 day 0, dose 2 days 1-3) as all trumped by those for 1st dose
	replace cutp8=999 if cutp7>=cutp11 
	replace cutp9=9999 if cutp7>=cutp11 
	replace cutp10=99999 if cutp7>=cutp11 
	replace cutp11=999999 if cutp7>=cutp11

	*if 2nd risk window doesn't overlap with 1st risk window then other dose 2 windows (prior to main risk window 4-42) are trumped by those for 1st dose
	*but any non-risk time after first dose risk window may still be part of  dose 2 window (-28 days, day 0, day 1-3)
	* start dose 2 administrative periods at end of dose 1 risk window (dose 1 risk trumps dose 1 administrative)
	replace cutp8= max(cutp7, cutp8) if vacc_date2!=. & cutp7<cutp11 
	replace cutp9=max(cutp7, cutp9) if vacc_date2!=. & cutp7<cutp11 
	replace cutp10=max(cutp7, cutp10) if vacc_date2!=. & cutp7<cutp11 

	*add in weekly time period in case we need it
	*put extra bit of week in with last week

	egen test=max(end)
	gen test2=floor(test/7) +12
	local n=test2[1]
	display `n'
	display "weeks"
	foreach i of numlist 13/`n' {
		 display `i'
		 gen cutp`i' = (`i'-12)*7
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
		
	save "`c(pwd)'/output/temp_data/sccs_popn_2doses_`j'_`brand'.dta", replace
		
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
		
		*1. create variable including second dose risk windows for BP, TM and for GBS
			
			recode exgr1 (0=0) (1=1) (2=2) (3=3) (4=4) (5=0) (6=5) (7=6) (8=7) (9=8), generate(vacc1_`j'_incl_dose2)
				** vacc1_`j'_dose2 has 9 levels, non-risk (0), pre-vacc low (1), day 0 (2) days 1-3 (3), days 4-28/42 (4),  pre-vacc low dose 2 (5), day 0 dose2 (6) days 1-3 dose2 (7), days 4-42 dose 2 (8)
				label define vacc1_`j'_incl_dose21 0 "non-risk" 1 "pre-vacc" 2 "day 0" 3 "days 1-3" 4 "days 4-28 or 42"  5 "pre-vacc dose2" 6 "day 0 dose2" 7 "days 1-3 dose 2" 8 "days 4-28 or 42 dose2"
				label values vacc1_`j'_incl_dose2 vacc1_`j'_incl_dose21	
		
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
	   
	 
	 *count how many outcomes there are on the day of vaccination
	 display "NUMBER OF OUTCOMES ON DAY OF 1st VACCINATION"
	 display "`j'"
	 count if nevents==1 & vacc1_`j'_incl_dose2==2
	 
	 display "NUMBER OF OUTCOMES ON DAY OF 2nd VACCINATION"
	 display "`j'"
	 count if nevents==1 & vacc1_`j'_incl_dose2==6
	 
	display "TABLE OF NUM EVENTS BY RISK WINDOW"
	tabstat  nevents, s(sum) by(vacc1_`j'_incl_dose2)format(%9.0f)

	display "TABLE OF NUM EVENTS BY WEEK"
	tabstat  nevents, s(sum) by(week)format(%9.0f)
	 
	 display "****************"
	 display "****OUTCOME*****"
	 display "`j'"
	 display "****************"
	 display "`brand' INCLUDING SECOND DOSE"
	** vacc1_`j'_dose2 has 8 levels, non-risk (0), pre-vacc low (1), day 0 (2) days 1-3 (3), days 4-28/42 (4),  pre-vacc low dose 2 (5), day 0 dose2 (6) days 1-3 dose2 (7), days 4-42 dose 2 (8)
	 
	capture noisily xtpoisson nevents ib0.vacc1_`j'_incl_dose2  , fe i(patient_id) offset(loginterval) eform
	 
	if _rc+(e(converge)==0) == 0 {
		mat b = r(table) 
 
		forvalues v = 1/7 {
			local k = `v' + 1 
			post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	}
	else di "DID NOT CONVERGE - `brand' SECOND DOSE UNADJUSTED"

	display "add in week"
	capture noisily xtpoisson nevents ib0.vacc1_`j'_incl_dose2 ib0.week , fe i(patient_id) offset(loginterval) eform
	
	if _rc+(e(converge)==0) == 0 {
		mat b = r(table) 
 
		forvalues v = 1/7 {
			local k = `v' + 1 
			post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	}
	else di "DID NOT CONVERGE - `brand' SECOND DOSE 1 WEEK"
	 
	display "add in 2 week period"
	capture noisily xtpoisson nevents ib0.vacc1_`j'_incl_dose2 ib0.two_week , fe i(patient_id) offset(loginterval) eform
	
	if _rc+(e(converge)==0) == 0 {
		mat b = r(table) 
 
		forvalues v = 1/7 {
			local k = `v' + 1 
			post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	}
	else di "DID NOT CONVERGE - `brand' SECOND DOSE 2 WEEK"
	 
	restore
 
 }
 
* Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary_second_doses_`brand'", clear
export delimited using "`c(pwd)'/output/tables/results_summary_second_doses_`brand'.csv", replace


log close
 




