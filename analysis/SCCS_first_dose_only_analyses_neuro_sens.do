/*==============================================================================
DO FILE NAME:			SCCS_first_dose_only_analyses_neuro_sens.do
PROJECT:				Vaccine Safety  
DATE: 					3rd Sept 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS sensitivity analyses of neuro events - GBS, TM and BP
							
							

DATASETS USED:			sccs_cutp_data_BP_`brand'.dta, sccs_cutp_data_TM_`brand'.dta, sccs_cutp_data_GBS_`brand'.dta
						(`brand' = AZ, PF, MOD)
DATASETS CREATED: 		
OTHER OUTPUT: 			logfile, printed to folder /logs
						tables, printed to folder /tables"

							
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
display `brand'


* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_first_dose_only_sens_analyses_`brand'.log", replace 





* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_sens_`brand'", replace
		

foreach j in BP TM GBS{

use "`c(pwd)'/output/temp_data/sccs_cutp_data_`j'_`brand'.dta", clear


		
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
 
 
 
 *only consider post-vacc non-risk period (separate pre-vacc non-risk period)
  display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' POST-VACC NON-RISK PERIOD ONLY (separate pre-vacc non-risk period)"
** vacc1_BP_non_risk_post_vacc has 6 levels, non-risk post-vacc(0), pre-vacc low 14 days (1), day 0 (2) days 1-3 (3), days 4-28 (4) , pre-vacc non-risk (5)
** vacc1_TM_non_risk_post_vacc has 6 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-28 (4) , pre-vacc non-risk (5) 
** vacc1_GBS_non_risk_post_vacc has 6 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-42 (4),  pre-vacc non-risk (5)
				

 xtpoisson nevents ib0.vacc1_`j'_non_risk_post_vacc if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
    mat b = r(table) 
 
  forvalues v = 1/5 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Post-vacc non-risk period after 1d") ("") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 display "add in week"
 
 xtpoisson nevents ib0.vacc1_`j'_non_risk_post_vacc ib0.week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
     mat b = r(table) 
 
  forvalues v = 1/5 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Post-vacc non-risk period after 1d") ("add in week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 
 display "add in 2 week period"
 
 xtpoisson nevents ib0.vacc1_`j'_non_risk_post_vacc ib0.two_week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
      mat b = r(table) 
 
  forvalues v = 1/5 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Post-vacc non-risk period after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 }
 
 
 
 
 
 
 }
 
 
 
 
 * Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary", clear
export delimited using "`c(pwd)'/output/tables/results_summary_sens_`brand'.csv", replace


 log close
 
 
 

 
 

 

 
 
 
 