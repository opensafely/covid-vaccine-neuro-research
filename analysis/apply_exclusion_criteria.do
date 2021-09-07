/*==============================================================================
DO FILE NAME:			apply_exclusion_criteria
PROJECT:				Vaccine Safety  
DATE: 					28 June 2021  
AUTHOR:					A Schultze 
								
DESCRIPTION OF FILE:	program apply_exclusion_criteria
						applies inclusion and exclusion criteria to create individual SCCS 
						note: the only data management done is that required for
						population selection. outcome selection is required later on. 
DATASETS USED:			output/input_sccs_and_historical_cohort.csv
DATASETS CREATED: 		csvs as per project.yaml, into /tempdata
OTHER OUTPUT: 			logfile, printed to folder output/logs 
							
==============================================================================*/

/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"

* set ado path
adopath + "`c(pwd)'/analysis/extra_ados"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/apply_exclusion_criteria.log", replace 


* IMPORT DATA=================================================================*/ 

import delimited `c(pwd)'/output/input_sccs_and_historical_cohort.csv, clear

* DATA CLEANING===============================================================*/ 
* Create the variables required to apply exclusion criteria 

* convert string variables to date (note: only for those required to select population)
foreach var of varlist first_any_vaccine_date ///
					   first_pfizer_date /// 
					   first_az_date ///
					   first_moderna_date ///
					   death_date ///
					   dereg_date ///
					   fu_ms_no_gp ///
					   fu_cidp_gp { 
					   	
						capture confirm string variable `var'
						if _rc == 0 { 
							rename `var' _tmp
							gen `var' = date(_tmp, "YMD")
							drop _tmp
							format %d `var'
						}
					   }

/* Censor Date
This is needed as the vaccines for the SCCS need to be administrated prior to censoring 
Censor calendar date is 3 weeks prior to last SUS availability, currently approx 1 July 2021 */ 

* Overall censor date based on administrative variables 

gen calendar_censor_date = date("11/06/2021", "DMY")
gen index_date = date("01/07/2020", "DMY")
gen censor_date = min(calendar_censor_date, death_date, dereg_date)
format censor_date %d

* ceck censor_date 
summarize calendar_censor_date, d
summarize censor_date, d 

gen check_death = 1 if death_date != . 
replace check_death = 0 if check_death == . 

tab check_death, m 

* check FU time 
gen fu_time = censor_date - index_date
gen check_fu = 1 if fu_time == . 
tab check_fu, m 

summarize fu_time, d 

* APPLY CRITERIA==============================================================*/
* Check the inclusion and exclusion criteria per protocol, apply those not yet applied 
* Exports several csvs according to different requirements 

* Known Gender
datacheck inlist(sex,"M", "F"), nolist

* Adult and known age 
datacheck age >= 18 & age <= 105, nolist

* Registration history and alive 
datacheck has_baseline_time == 1, nolist
datacheck has_died == 0, nolist

* Known care home 
datacheck known_care_home == 1, nolist

* Known IMD
datacheck imd != . & imd > 0, nolist

* Pregnancy 
datacheck pregnancy != 1, nolist

* Confirm one row per patient 
duplicates tag patient_id, generate(dup_check)
assert dup_check == 0 
drop dup_check

* POTENTIALLY ELIGIBLE CONTROLS 
export delimited using `c(pwd)'/output/input_historical_controls.csv, replace 

* POTENTIALLY ELIGIBLE EXPOSED PEOPLE 
* Apply exposure requirement and export 'cases' for sccs and for matching in the cohort studies 

noi di "DROP IF HAVE NOT RECEIVED A COVID VACCINE"
count
drop if first_any_vaccine_date == . 
count

noi di "DROP IF NEVER RECEIVED VACCINES OF INTEREST"
count 
drop if first_pfizer_date == . & first_az_date == . & first_moderna_date == . 
count 

noi di "DROP IF PFIZER AND AZ ON SAME DATE"
count 
drop if first_pfizer_date == first_az_date & first_pfizer_date != . 
count 

noi di "DROP IF MODERNA AND AZ ON SAME DATE" 
count
drop if first_moderna_date == first_az_date & first_moderna_date != . 
count 

noi di "DROP IF MODERNA AND PFIZER ON SAME DATE"
count
drop if first_moderna_date == first_pfizer_date & first_moderna_date != . 
count

* create a variable which is the minimum of Pfizer, AZ and moderna dates 
* this should be equivalent to first_any_vaccine_date in real data, but will use this so that we can run on dummy data 
gen first_pfizer_az_moderna_date = min(first_az_date, first_pfizer_date, first_moderna_date)

* check equivalence for real data 
datacheck first_pfizer_az_moderna_date == first_any_vaccine_date, nolist 

noi di "COUNT IF THE FIRST VACCINE WAS OF UNKNOWN TYPE" 
* Note, ideally these would be dropped, but the equivalence statement required reduces the dummy datasize so much it becomes unworkable 
* Not dropping them has no impact as they are dropped for the brand-specific case series as is 
* Therefore, a binary indicator variable is created indicating unknown vaccine type instead
* If needed, these can be excluded from the historical case population (the only output in which they are included)

gen unknown_first_dose = 1 if (first_pfizer_date != first_any_vaccine_date) & (first_az_date != first_any_vaccine_date) & (first_moderna_date != first_any_vaccine_date)
replace unknown_first_dose = 0 if unknown_first_dose == . 
tab unknown_first_dose, m 


* AZ COHORT 
preserve

* Drop if earliest vaccine is not AZ
count 
gen earliest_vaccine = "AZ" if first_az_date == first_pfizer_az_moderna_date & first_az_date != . 
drop if earliest_vaccine != "AZ"
count 

* Drop if first AZ not before censoring
drop if first_az_date == . | first_az_date >= censor_date
count 

* count outcomes for sense checking 
gen check_BP = (any_bells_palsy != "")
gen check_TM = (any_transverse_myelitis != "")
gen check_GBS = (any_guillain_barre != "")

safetab check_BP, m
safetab check_TM, m
safetab check_GBS, m

drop check_* 

* Export cohort 
export delimited using `c(pwd)'/output/input_AZ_cases.csv, replace 

restore

* PFIZER COHORT 
preserve

* Drop if earliest vaccine is not Pfizer
count 
gen earliest_vaccine = "Pfizer" if first_pfizer_date == first_pfizer_az_moderna_date & first_pfizer_date != . 
drop if earliest_vaccine != "Pfizer"
count 

* Drop if first Pfizer not before censoring
drop if first_pfizer_date == . | first_pfizer_date >= censor_date
count 

* count outcomes for sense checking 
gen check_BP = (any_bells_palsy != "")
gen check_TM = (any_transverse_myelitis != "")
gen check_GBS = (any_guillain_barre != "")

safetab check_BP, m
safetab check_TM, m
safetab check_GBS, m

drop check_* 

* Export cohort 
export delimited using `c(pwd)'/output/input_PF_cases.csv, replace 

restore

* MODERNA COHORT 
preserve

* Drop if earliest vaccine is not Moderna
count 
gen earliest_vaccine = "Moderna" if first_moderna_date == first_pfizer_az_moderna_date & first_moderna_date != . 
drop if earliest_vaccine != "Moderna"
count 

* Drop if first Moderna not before censoring
drop if first_moderna_date == . | first_moderna_date >= censor_date
count 

* count outcomes for sense checking 
gen check_BP = (any_bells_palsy != "")
gen check_TM = (any_transverse_myelitis != "")
gen check_GBS = (any_guillain_barre != "")

safetab check_BP, m
safetab check_TM, m
safetab check_GBS, m

drop check_* 

* Export cohort 
export delimited using `c(pwd)'/output/input_MOD_cases.csv, replace 

restore

* SCCS case series will be created sepatately in a different Stata program 

* CLOSE LOG===================================================================*/ 

log close












 
					   
					   
					   
					   
					   
