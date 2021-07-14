/*==============================================================================
DO FILE NAME:			00_apply_exclusion_criteria
PROJECT:				Vaccine Safety  
DATE: 					28 June 2021  
AUTHOR:					A Schultze 
								
DESCRIPTION OF FILE:	program 00
						applies inclusion and exclusion of PRIMIS variables 
						creates csv of cases and controls for matching
						creates SCCS cohorts for all outcomes 
						note: the only data management done is that required for
						population selection. 
DATASETS USED:			output/input_core.csv
DATASETS CREATED: 		csvs as per project.yaml, into /tempdata
OTHER OUTPUT: 			logfile, printed to folder output/logs 
							
==============================================================================*/

/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"

* set ado path
adopath + "$projectdir/analysis/extra_ados"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/00_apply_exclusion_criteria.log", replace 


* IMPORT DATA=================================================================*/ 

import delimited `c(pwd)'/output/input_core.csv, clear

* DATA CLEANING===============================================================*/ 
* Create the variables required to apply exclusion criteria 

* convert string variables to date (note: only for those required to select population)
foreach var of varlist ast_dat ///
					   astadm_dat ///
					   astrxm1_dat ///
					   astrxm2_dat ///
					   astrxm3_dat ///
					   resp_cov_dat ///
					   chd_cov_dat ///
					   ckd_cov_dat ///
					   ckd15_dat ///
					   ckd35_dat ///
					   cld_dat ///
					   diab_dat ///
					   immrx_dat ///
					   immdx_cov_dat ///
					   cns_cov_dat ///
					   spln_cov_dat ///
					   bmi_dat ///
					   bmi_stage_dat ///
					   sev_obesity_dat ///
					   dmres_dat ///
					   sev_mental_dat ///
					   smhres_dat ///
					   learndis_dat ///
					   first_any_vaccine_date ///
					   first_pfizer_date /// 
					   first_az_date ///
					   first_moderna_date ///
					   any_vte ///
					   any_pe ///
					   any_cvt_vte ///
					   death_date ///
					   dereg_date { 
					   	
						capture confirm string variable `var'
						rename `var' _tmp
						gen `var' = date(_tmp, "YMD")
						drop _tmp
						format %d `var'
							
					   }
/* PRIMIS variables 
Note, this logic and variable names follows PHE guidance for the creation of PRIMIS
groups ('SARS-Cov2 (COVID-19) Vaccine Uptake Reporting Specification Collection 2020/2021 version 1')
*/

* Patients with immunosuppression 
gen immuno_group = (immrx_dat != .)
replace immuno_group = 1 if immdx_cov_dat != . 

* Patients with CKD 
gen ckd_group = (ckd_cov_dat != . ) 
replace ckd_group = 1 if ckd35_dat >= ckd15_dat & ckd35_dat != . 

* Patients with asthma (admission or several recent prescriptions)
gen ast_group = (astadm_dat != .)
replace ast_group = 1 if ( ast_dat != . /// 
						 & astrxm1_dat ! = . /// 
						 & astrxm2_dat ! = . /// 
						 & astrxm3_dat ! = .) 

* Patients with CNS disease 
gen cns_group = (cns_cov_dat != . )

* Patients with Chronic Respiratory Disease 
gen resp_group = (ast_group == 1) 
replace resp_group = 1 if resp_cov_dat != . 

* Patients with Morbid Obesity
* replace invalid values (0) with missing 
replace bmi_val = . if bmi_val <= 0  

gen bmi_group = 1 if bmi_val >= 40 & bmi_val != . 
replace bmi_group = 1 if sev_obesity_dat > bmi_dat & bmi_dat != . 
replace bmi_group = 0 if bmi_group == . 

* Patients with Diabetes 

gen diab_group = 1 if diab_dat > dmres_dat & dmres_dat != . 
replace diab_group = 1 if diab_dat != . & dmres_dat == . 
replace diab_group = 0 if diab_group == . 

* Patients with Severe Mental Health 

gen sevment_group = 1 if sev_mental_dat > smhres_dat & smhres_dat != . 
replace sevment_group = 1 if sev_mental_dat != . & smhres_dat == . 
replace sevment_group = 0 if sevment_group == . 

* At Risk Group 
* (note learning diability not included as added to risk groups later on)
gen atrisk_group = 1 if immuno_group == 1 
replace atrisk_group = 1 if ckd_group == 1 
replace atrisk_group = 1 if resp_group == 1 
replace atrisk_group = 1 if diab_group == 1 
replace atrisk_group = 1 if cld_dat != . 
replace atrisk_group = 1 if cns_group == 1 
replace atrisk_group = 1 if chd_cov_dat != . 
replace atrisk_group = 1 if spln_cov_dat != . 
replace atrisk_group = 1 if sevment_group == 1 

replace atrisk_group = 0 if atrisk_group == . 

/* Censor Date
This is needed as the outcomes for the SCCS need to occur prior to censoring */ 

gen calendar_censor_date = date("11/03/2021", "DMY")
gen censor_date = min(calendar_censor_date, death_date, dereg_date)

* APPLY CRITERIA==============================================================*/
* Check the inclusion and exclusion criteria per protocol, apply those not yet applied 
* Exports several csvs according to different requirements 

* Known Gender
datacheck inlist(sex,"M", "F"), nolist

* Adult and known age 
datacheck age >= 16 & age <= 105, nolist

* Registration history and alive 
datacheck has_baseline_time == 1, nolist
datacheck has_died == 0, nolist

* Known care home 
datacheck known_care_home == 1, nolist

* Pregnancy 
datacheck pregnancy != 1, nolist

* Prior VTE 
datacheck prior_any_vte != 1, nolist 

* Confirm one row per patient 
duplicates tag patient_id, generate(dup_check)
assert dup_check == 0 
drop dup_check

* Over 65 OR in a PRIMIS group 
noi di "DROP THOSE NOT ELIGIBLE FOR VACCINE DURING THE PERIOD" 
count
drop if age < 65 & atrisk_group == 0
count

datacheck (age >= 65 | atrisk_group == 1), nolist 

* POTENTIALLY ELIGIBLE CONTROLS 
export delimited using `c(pwd)'/output/input_controls.csv, replace 

* POTENTIALLY ELIGIBLE CASES 
* Apply exposure requirement and export 'cases' for sccs and for matching in the cohort studies 

noi di "DROP IF HAVE NOT RECEIVED A COVID VACCINE"
count
drop if first_any_vaccine_date == . 
count

noi di "DROP IF RECEIVED UNKNOWN OR SOMETHING OTHER THAN PFIZER/AZ"
count 
drop if first_pfizer_date == . & first_az_date == . 
count 

noi di "DROP IF PFIZER AND AZ ON SAME DATE"
count 
drop if first_pfizer_date == first_az_date 
count 

noi di "DROP IF PFIZER AND MODERNA ON SAME DATE"
count 
drop if first_pfizer_date == first_moderna_date & first_pfizer_date != . 
count 

noi di "DROP IF AZ AND MODERNA ON SAME DATE"
count 
drop if first_az_date == first_moderna_date & first_az_date != . 
count 

* AZ COHORT 
noi di "AZ FIRST DOSE EXPOSED DURING FU PERIOD"
count 
drop if first_az_date == . | first_az_date >= censor_date
count 

export delimited using `c(pwd)'/output/input_az_cases.csv, replace 

* PFIZER COHORT 
noi di "PFIZER FIRST DOSE EXPOSED DURING FU PERIOD"
count 
drop if first_pfizer_date == . | first_pfizer_date >= censor_date
count 

export delimited using `c(pwd)'/output/input_pfizer_cases.csv, replace 

* SCCS case series will be created sepatately in a different Stata program 

* CLOSE LOG===================================================================*/ 

log close












 
					   
					   
					   
					   
					   
