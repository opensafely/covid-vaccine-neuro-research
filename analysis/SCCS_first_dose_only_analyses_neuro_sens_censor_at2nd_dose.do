/*==============================================================================
DO FILE NAME:			SCCS_first_dose_only_analyses_neuro_sens_censor_at2nd_dose.do
PROJECT:				Vaccine Safety  
DATE: 					19th Aug 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS primary analysis of neuro events - GBS, TM and BP
						sensitivity analysis- restriction follow up to earliest of 12 weeks after dose1, and date of second dose	
							

DATASETS USED:			input_AZ_cases.csv, input_PF_cases.csv, input_MOD_cases.csv
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfile, printed to folder /logs
						tables, printed to folder /tables
						
							
==============================================================================*/



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
log using "`c(pwd)'/output/logs/SCCS_first_dose_only_sens_censor_at2nd_dose_`brand'.log", replace 


*runs through for each brand

* IMPORT DATA=================================================================*/ 



import delimited using `c(pwd)'/output/input_`brand'_cases.csv



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

foreach var of varlist second_any_vaccine_date second_pfizer_date second_az_date second_moderna_date BP TM GBS first_positive_covid_test bells_palsy_gp bells_palsy_hospital bells_palsy_emergency{ 
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

					   
*post-hoc sensiitivity analysis
*include only those BP with a GP record

gen BP_anyGPdate=BP 
replace BP_anyGPdate=. if bells_palsy_gp==.		
format %td BP_anyGPdate			   
					   
* create flag for first dose >=1st Jan for AZ PF comparison sensitivity analysis

gen incl_AZ_PF_compare=1 if (AZ_date>=d("01jan2021") & first_brand=="AZ") | (PF_date>=d("01jan2021") & first_brand=="PF")


*previous covid infection flag

gen prior_covid=1 if first_brand=="`brand'" & first_positive_covid_test < `brand'_date 


rename history_any_transverse_myelitis history_TM
rename history_any_bells_palsy history_BP
rename history_any_guillain_barre history_GBS

*for completeness in loop below
gen history_BP_anyGPdate= history_BP

*create flag to drop if cidp date before gbs date
gen flag_X_before_GBS=1 if fu_cidp_gp <= GBS & GBS!=.


	
*create flag to drop TM if have MS/neuromyelitis_optica  before TM date
gen flag_X_before_TM=1 if fu_ms_no_gp<=TM & TM!=.


*nothing to drop before BP but need dummy flag for loop
gen flag_X_before_BP=. if BP!=.
gen flag_X_before_BP_anyGPdate=. if BP_anyGPdate!=.	

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
replace end= end_date_dose2 - study_start if (censor_fu_dose2==1 & end_date_dose2<end)

replace end= second_any_vaccine_date - study_start if (censor_fu_diff_brand2==1 & second_any_vaccine_date<end)


****ISSUE WITH SECOND_ANY_VACCINE_DATE VARIABLE?

count if second_any_vaccine_date==. & (second_pfizer_date!=. | second_az_date!=. | second_moderna_date!=.)


*there will only be one date in any of the second dose varaibles, i.e. same date in second_az_date and second_any_vaccine_date if second dose is AZ and no other vaccines recieved 
rename second_az_date second_AZ_date
rename second_pfizer_date second_PF_date
rename second_moderna_date second_MOD_date

*time since study start of dose 2
gen vacc_date2= second_`brand'_date - study_start if incl_2nd_dose_`brand'==1 & second_`brand'_date!=.

gen vacc2=1 if (vacc_date2!=.) & vacc_date2 <= end 
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


*censor follow up at 12 weeks after 1st dose or second vaccine date if earlier
gen vacc1_plus_12wks=cutp6 +84
replace cutp2=vacc1_plus_12wks if vacc1_plus_12wks<cutp2
replace cutp2=vacc_date2 if vacc_date2<cutp2


*add in weekly time period in case we need it
*put extra bit of week in with last week


egen test=max(cutp2)
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




**** Results output
	
* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_sens_censor_at2nd_dose_`brand'", replace
		


*loop over each outcome

*foreach j of varlist BP TM GBS BP_anyGPdate{
foreach j of varlist BP{
preserve


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
			
			
		*BP_anyGPdate should be the same as for BP
		gen vacc1_BP_anyGPdate=vacc1_BP
	
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
 display "NUMBER OF OUTCOMES ON DAY OF VACCINATION"
 display "`j'"
 count if nevents==1 & vacc1_`j'==2
 
 *count number of outcomes overall
 display "NUMBER OF OUTCOMES"
 display "`j'"
 count if nevents==1
 
 
* Setup file for posting results
/*  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_primary_`brand'", replace
 
*/
 
display "TABLE OF NUM EVENTS BY RISK WINDOW"
tabstat  nevents, s(sum) by(vacc1_`j')format(%9.0f)

display "TABLE OF NUM EVENTS BY WEEK"
tabstat  nevents, s(sum) by(week)format(%9.0f)
 
 
 
 
 
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' RISK WINDOW AFTER 1ST DOSE CENSORED AT 2ND DOSE OR 12 WEEKS AFTER FIRST DOSE"
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
 
 
 xtpoisson nevents ib0.vacc1_`j', fe i(patient_id) offset(loginterval) eform

  if _rc==0{
  mat b = r(table) 
 

 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Risk window after 1d censor 2nd dose") ("") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 
 else di "DID NOT CONVERGE - `brand' RISK WINDOW AFTER 1ST DOSE CENSORED AT 2ND DOSE OR 12 WEEKS AFTER FIRST DOSE - NO PERIOD"
 
 display "add in week"
 
  xtpoisson nevents ib0.vacc1_`j' ib0.week , fe i(patient_id) offset(loginterval) eform
  
  
  if _rc==0{  
   mat b = r(table) 

 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Risk window after 1d censor 2nd dose") ("add in week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 
 else di "DID NOT CONVERGE - `brand' RISK WINDOW AFTER 1ST DOSE CENSORED AT 2ND DOSE OR 12 WEEKS AFTER FIRST DOSE - WEEK ADJ"
 
 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week, fe i(patient_id) offset(loginterval) eform
 
  if _rc==0{
  mat b = r(table) 
 
 forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Risk window after 1d censor 2nd dose") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 else di "DID NOT CONVERGE - `brand' RISK WINDOW AFTER 1ST DOSE CENSORED AT 2ND DOSE OR 12 WEEKS AFTER FIRST DOSE - 2 WEEK ADJ"
 

 restore
}
 
 
 
  * Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary_sens_censor_at2nd_dose_`brand'", clear
export delimited using "`c(pwd)'/output/tables/results_summary_sens_censor_at2nd_dose_`brand'.csv", replace

 
log close
