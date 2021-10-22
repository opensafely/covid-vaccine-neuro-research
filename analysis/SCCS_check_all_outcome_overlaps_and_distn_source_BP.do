
/*==============================================================================
DO FILE NAME:			SCCS_check_all_outcome_overlaps_and_distn_source_BP.do
PROJECT:				Vaccine Safety  
DATE: 					5th October 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	after reporting initial results to colleagues at PHE and MHRA
						- examine distribution of source of BP cases (GP, hospital, emergency care)
						- count how many individuals have multiple outcomes
						
													

DATASETS USED:			input_AZ_cases.csv, input_PF_cases.csv, input_MOD_cases.csv
						sccs_popn_BP_`brand'.dta, sccs_popn_TM_`brand'.dta, sccs_popn_GBS_`brand'.dta (`brand' = AZ, PF, MOD)
						sccs_cutp_data_BP_`brand'
DATASETS CREATED: 		
						
						
OTHER OUTPUT: 			logfile, printed to folder /logs
						
						
							
==============================================================================*/


/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"
capture	mkdir "`c(pwd)'/output/plots"
capture	mkdir "`c(pwd)'/output/tables"
capture	mkdir "`c(pwd)'/output/temp_data"

* set ado path
adopath + "`c(pwd)'/analysis/extra_ados"


clear

*variable to cycle through each brand (AZ, PF, MOD)

local brand `1'


display "`brand'"


* open a log file
cap log close
log using "`c(pwd)'/output/logs/SSCCS_check_all_outcome_overlaps_and_distn_source_BP_`brand'.log", replace 


*runs through for each brand


*************************************************************************
*examine any differences between of source of BP cases (GP, hospital, emergency care) of being in risk window or not
*************************************************************************

import delimited using `c(pwd)'/output/input_`brand'_cases.csv



gen BP=any_bells_palsy


foreach var of varlist BP bells_palsy_gp bells_palsy_hospital bells_palsy_emergency{ 
						rename `var' _tmp
						gen `var' = date(_tmp, "YMD")
						drop _tmp
						format %d `var'
							
					   }

gen first_gp=1 if bells_palsy_gp==BP
gen first_hosp=1 if bells_palsy_hospital==BP					   
gen first_emer=1 if bells_palsy_emergency==BP


keep patient_id BP first_gp first_hosp first_emer bells_palsy_gp bells_palsy_hospital bells_palsy_emergency


*check that each individual has BP equal to >=1 of GP, hospital or emergency date
gen all_miss=1 if first_gp==. & first_hosp==. & first_emer==.

*datacheck all_miss==., nolist


*save an merge with final SCCS dataset for BP (some patient ids will be dropped and shouldn't be included in counts, etc.)

tempfile BP_source
save `BP_source', replace
		
	

use `c(pwd)'/output/temp_data/sccs_cutp_data_BP_`brand'.dta, clear

*sum person-time by window by patient 
collapse (sum) nevents interval, by(patient_id vacc1_BP)

merge m:1 patient_id using `BP_source'
datacheck _merge!=1, nolist
keep if _merge==3
drop _merge


*could be both hosp and GP on same date (or emergency care)	
*count number first gp, hosp, emergency

bysort patient_id: gen num=_n

di "TOTAL"
count if num==1

di "FIRST GP"
count if first_gp==1 & num==1

di "FIRST HOSPITAL"
count if first_hosp==1 & num==1

di "FIRST EMERGENCY"
count if first_emer==1 & num==1

di "FIRST GP & HOSP SAME DAY"
count if first_gp==1 & first_hosp==1 & num==1

di "FIRST GP & EMERGENCY SAME DAY"
count if first_gp==1 & first_emer==1 & num==1

di "FIRST EMERGENCY & HOSP SAME DAY"
count if first_emer==1 & first_hosp==1 & num==1

di "FIRST GP, HOSP & EMERGENCY ALL SAME DAY"
count if first_gp==1 & first_hosp==1 & first_emer==1 & num==1
	

*if have GP and other recod on same day-GP trumps? (hypothesis is that hospital only records are driving up BP and these may be incorrect diagnoses)

gen first_source="GP" if first_gp==1	
replace first_source="hosp" if first_hosp==1 & first_source==""
replace first_source="emer" if first_emer==1 & first_source==""

*datacheck first_source!="", nolist
drop if first_source==""

*interested in non-risk and risk window time only


keep if vacc1_BP==0 | vacc1_BP==4


preserve


*want to know if event is in risk window or not
keep if nevents==1

gen risk_event=1 if vacc1_BP==4
replace risk_event=0 if risk_event==.

*any difference in an event being within a risk window between sources?
di "CHI-SQ TEST DIFFERENCES BETWEEN SOURCES FOR EVENT BEING IN RISK WINDOW OR NOT"
tabulate risk_event first_source, chi2

*any difference in an event being within a risk window between GP and hospital?
di "CHI-SQ TEST DIFFERENCES BETWEEN GP & HOSP SOURCES FOR EVENT BEING IN RISK WINDOW OR NOT"
tabulate risk_event first_source if first_source!="emer", chi2

restore


*add any checks on amount of person time in non risk/ risk window by source of BP diagnosis?
*any reason to think that follow up time in each window would differ by source?


*sum person-time and events by window by source
collapse (sum) nevents interval, by(vacc1_BP first_source)


*number of events per 10,000 person years

gen events_per10000pyrs=(nevents/(interval/365.25))*10000


*export and enter chi squared calc by hand for aggregate data?



	
	
***********************************************
*COUNT HOW MANY PATIENTS HAVE MULTIPLE OUTCOMES
***********************************************
	
	

use "`c(pwd)'/output/temp_data/sccs_popn_GBS_`brand'.dta", clear
keep patient_id
gen GBS=1
tempfile gbs_cases
save `gbs_cases', replace
 
use "`c(pwd)'/output/temp_data/sccs_popn_BP_`brand'.dta", clear
keep patient_id
gen BP=1
tempfile bp_cases
save `bp_cases', replace


use "`c(pwd)'/output/temp_data/sccs_popn_TM_`brand'.dta", clear
keep patient_id 
gen TM=1 
 
 
merge 1:1 patient_id using `gbs_cases'
drop _merge

merge 1:1 patient_id using `bp_cases'
drop _merge

di "OVERLAP NUMBER PATIENTS BP & GBS" 
count if BP==1 & GBS==1


di "OVERLAP NUMBER PATIENTS BP & TM" 
count if BP==1 & TM==1
 

di "OVERLAP NUMBER PATIENTS TM & GBS" 
count if TM==1 & GBS==1 
 

di "OVERLAP NUMBER PATIENTS GBS, TM & BP" 
count if BP==1 & TM==1 & GBS==1  
 
log close 
 
 