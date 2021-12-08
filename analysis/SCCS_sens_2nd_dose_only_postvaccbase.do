/*==============================================================================
DO FILE NAME:			SCCS_sens_2nd_dose_only_postvaccbase.do
PROJECT:				Vaccine Safety  
DATE: 					3rd December 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS second dose sensitivity analysis only restricting to post vaccination follow up time
						To allow for second dose being potentially event dependent (after 1st dose)
							

DATASETS USED:			input_AZ_cases.csv, input_PF_cases.csv and input_MOD_cases.csv
DATASETS CREATED: 		csvs as per project.yaml, into /tempdata
OTHER OUTPUT: 			logfile, `c(pwd)'/output/logs/SCCS_sens_2nd_dose_only_postvaccbase_`brand' (brand=AZ, PF, MOD)
						tables, printed to folder `c(pwd)'/output/tables  
							
==============================================================================*/


/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"

capture	mkdir "`c(pwd)'/output/tables"
capture	mkdir "`c(pwd)'/output/temp_data"

* set ado path
adopath + "$projectdir/analysis/extra_ados"

*variable to cycle through each brand (AZ, PF, MOD)
local brand `1'
display "`brand'"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_sens_2nd_dose_only_postvaccbase_`brand'.log", replace 

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
*create flag (to censor) for more than one brand given on same date for second dose
*2nd DOSE AZ AND PFIZER ON SAME DATE

gen censor_fu_dose2=1 if second_pfizer_date == second_az_date & second_az_date!=. & (first_brand=="AZ" | first_brand=="PF")

* 2nd DOSE AZ AND MODERNA ON SAME DATE
replace censor_fu_dose2=1 if second_az_date == second_moderna_date & second_az_date != . & (first_brand=="AZ" | first_brand=="MOD")

* 2nd DOSE PFIZER AND MODERNA ON SAME DATE
replace censor_fu_dose2=1 if second_pfizer_date == second_moderna_date & second_pfizer_date != . & (first_brand=="PF" | first_brand=="MOD")

gen end_date_dose2=min(second_az_date, second_pfizer_date, second_moderna_date) if censor_fu_dose2==1

*also need to censor at second dose brand different to first
* create flags for when second dose brand is different to first

 
gen censor_fu_diff_brand2=1 if ((first_brand=="AZ" & second_pfizer_date!=.) | (first_brand=="AZ" & second_moderna_date!=.)) 
replace censor_fu_diff_brand2=1 if ((first_brand=="PF" & second_az_date!=.) | (first_brand=="PF" & second_moderna_date!=.)) 
replace censor_fu_diff_brand2=1 if ((first_brand=="MOD" & second_pfizer_date!=.) | (first_brand=="MOD" & second_az_date!=.)) 


*if second dose unspecified- assume the same as first
gen unspec_second_dose=1 if second_any_vaccine_date!=. & second_az_date==. & second_pfizer_date==. & second_moderna_date==.

*unspec second dose but AZ first
replace second_az_date=second_any_vaccine_date if second_az_date==. & unspec_second_dose==1 & first_brand=="AZ"

*unspec second dose but PF first
replace second_pfizer_date=second_any_vaccine_date if second_pfizer_date==. & unspec_second_dose==1 & first_brand=="PF"

*unspec second dose but MOD first
replace second_moderna_date=second_any_vaccine_date if second_moderna_date==. & unspec_second_dose==1 & first_brand=="MOD"


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

gen vacc2=1 if (vacc_date2!=.) & vacc_date2 <= end 


*only want to include those that had a second dose

drop if vacc_date2==.


*generate cut points 
gen cutp1=start
gen cutp2=end

*cutpoints for risk windows
*want -28 (TM or GBS) / -14 (BP) days removed in primary for healthy vaccinee bias
* main window 4-28 days inclusive (BP or TM), 4-42 days (GBS)

*ASSERT >=21 days between doses
datacheck vacc_date2- vacc_date1 >=21 if vacc_date2!=., nolist


*NO LONGER NEED FIRST DOSE
drop vacc_date1

* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) str20(vlab) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_sens_2nd_dose_only_postvaccbase_`brand'", replace
		
foreach j in BP TM GBS {
	preserve


	gen outcome="`j'"
	display "************ OUTCOME `j'"


	*risk windows for second dose 4-42 days 
	gen cutp3=vacc_date2-0
	gen cutp4=vacc_date2+3
	gen cutp5=vacc_date2+28 if outcome=="BP" | outcome=="TM"
	replace cutp5=vacc_date2+42 if outcome=="GBS"



	*add in weekly time period in case we need it
	*put extra bit of week in with last week

	egen test=max(end)
	gen test2=floor(test/7) +5
	local n=test2[1]
	display `n'
	display "weeks"
	foreach i of numlist 6/`n' {
		 display `i'
		 gen cutp`i' = (`i'-5)*7
	 }

	local last=`n'+1
	display `last'
	gen cutp`last'=cutp2
	*any remaining time up to end of study period (just to double check)

	
	*REPLACE START OF FOLLOW UP TO BE VACC 2 DATE
	
	replace cutp1=cutp3-1
	
	
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
	*CHANGED THIS TO EVENTS AFTER VACC2 DATE	
	display "THIS MANY HAVE EVENT PRIOR TO DOSE 2 `j'"
	drop if eventday<cutp1
	display "THIS MANY HAVE EVENT AFTER END FU `j'"
	drop if eventday>=end
		
	***ALSO DOUBLE CHECK HAVE VACCINE WITHIN FU TIME****
	*CHANGED TO BE VACCINE 2
	drop if vacc_date2<cutp1
	drop if vacc_date2>=end

	*local macro containing event count 
	count 
	local eventnum = r(N)
	display "THIS MANY HAVE AT LEAST ONE EVENT"
	di "`eventnum'"
	
	*summary of length of follow up time
	*EDIT TO BE LENGTH OF TIME BETWEEN NEW START (CUTP1= VACC2 DATE) &  END (=CUTP2)
	display "SUMMARY OF FOLLOW UP TIME IN STUDY"
	gen time_study=cutp2-cutp1
	summ time_study, detail
		

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
		
		generate exgr1 = type-2 if type>=3 & type<=5
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
			
			recode exgr1 (1=1) (2=2) (3=3), generate(vacc2_`j'_sens)
				** vacc1_`j'_dose2 has 4 levels, non-risk (0), day 0 dose2 (1) days 1-3 dose2 (2), days 4-42 dose 2 (3)
				label define vacc2_`j'_sens1 0 "non-risk post-vacc"  1 "day 0 dose2" 2 "days 1-3 dose 2" 3 "days 4-28 or 42 dose2"
				label values vacc2_`j'_sens vacc2_`j'_sens1		

	   *EXPECT FIRST WEEKS FROM STUDY_START TO BE MISSING
	   *weekly exposure groups
	   *up to maximum cutp for weeks defined by max length of study_end
	   
	   egen test3=max(type)
	   local w=test3[1]
	   
		generate exgr2 = type-6 if type>=6 & type<=`w'
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

	 
	 display "NUMBER OF OUTCOMES ON DAY OF 2nd VACCINATION"
	 display "`j'"
	 count if nevents==1 & vacc2_`j'_sens==1
	 
	*CHECK ONLY RELEVANT RISK WINDOWS ARE HERE*****
	display "TABLE OF NUM EVENTS BY RISK WINDOW"
	tabstat  nevents, s(sum) by(vacc2_`j'_sens)format(%9.0f)

	display "TABLE OF NUM EVENTS BY WEEK"
	tabstat  nevents, s(sum) by(week)format(%9.0f)
	 
	 display "****************"
	 display "****OUTCOME*****"
	 display "`j'"
	 display "****************"
	 display "`brand' SENSITIVITY RESTRICTED TO SECOND DOSE ONLY- FOLLOW UP FROM 2ND DOSE DATE"
	** vacc1_`j'_dose2 has 4 levels, non-risk post vacc2 (0), day 0 dose2 (1) days 1-3 dose2 (2), days 4-42 dose 2 (3)
	 
	capture noisily xtpoisson nevents ib0.vacc2_`j'_sens  , fe i(patient_id) offset(loginterval) eform
	 
	if _rc+(e(converge)==0) == 0 & `eventnum' > 5 {
		mat b = r(table) 
 
		forvalues v = 1/4 {
			local k = `v' + 1 
			local vlab: label vacc1_`j'_incl_dose21 `v'
			post `results'  ("`j'") ("`brand'") ("Second dose sens") ("") ("") ("`vlab'") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	}
	else di "DID NOT CONVERGE - `brand' SECOND DOSE UNADJUSTED"

	display "add in week"
	capture noisily xtpoisson nevents ib0.vacc1_`j'_incl_dose2 ib0.week , fe i(patient_id) offset(loginterval) eform
	
	if _rc+(e(converge)==0) == 0 & `eventnum' > 5 {
		mat b = r(table) 
 
		forvalues v = 1/4 {
			local k = `v' + 1 
			local vlab: label vacc1_`j'_incl_dose21 `v'
			post `results'  ("`j'") ("`brand'") ("Second dose sens") ("add in week") ("") ("`vlab'") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	}
	else di "DID NOT CONVERGE - `brand' SECOND DOSE 1 WEEK"
	 
	display "add in 2 week period"
	capture noisily xtpoisson nevents ib0.vacc1_`j'_incl_dose2 ib0.two_week , fe i(patient_id) offset(loginterval) eform
	
	if _rc+(e(converge)==0) == 0 & `eventnum' > 5 {
		mat b = r(table) 
 
		forvalues v = 1/4 {
			local k = `v' + 1 
			local vlab: label vacc1_`j'_incl_dose21 `v'
			post `results'  ("`j'") ("`brand'") ("Second dose sens") ("add in 2 week") ("") ("`vlab'") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	}
	else di "DID NOT CONVERGE - `brand' SECOND DOSE 2 WEEK"
	 
	restore
 
 }
 
* Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary_sens_2nd_dose_only_postvaccbase_`brand'", clear
export delimited using "`c(pwd)'/output/tables/results_summary_sens_2nd_dose_only_postvaccbase_`brand'.csv", replace


log close
 




