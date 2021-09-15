 /*==============================================================================
DO FILE NAME:			SCCS_first_dose_only_analyses_neuro_sens_risk.do
PROJECT:				Vaccine Safety  
DATE: 					3rd Sept 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS sensitivity analyses of neuro events - GBS, TM and BP
						Extend and Change Risk Windows 
DATASETS USED:			sccs_cutp_data_BP_`brand'.dta, sccs_cutp_data_TM_`brand'.dta, sccs_cutp_data_GBS_`brand'.dta
						(`brand' = AZ, PF, MOD)
DATASETS CREATED: 		
OTHER OUTPUT: 			logfile, printed to folder /logs
						resultsfile, printed to folder /tables"							
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
log using "`c(pwd)'/output/logs/SCCS_first_dose_only_analyses_neuro_sens_risk_`brand'.log", replace 


* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_sens_risk_`brand'", replace
		

foreach j in BP TM GBS{

use "`c(pwd)'/output/temp_data/sccs_cutp_data_`j'_`brand'.dta", clear

 *extended risk window
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "`brand' EXTENDED RISK WINDOW AFTER 1ST DOSE"
** vacc1_BP_ext has 5 levels, non-risk (0), pre-vacc low 14 days (1), day 0 (2) days 1-3 (3), days 4-42 (4) 	
** vacc1_TM_ext has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-42 (4) 
** vacc1_GBS_ext has 5 levels, non-risk (0), pre-vacc low 28 days (1), day 0 (2) days 1-3 (3), days 4-90 (4)  

 capture noisily xtpoisson nevents ib0.vacc1_`j'_ext if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
    mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Extended risk window after 1d") ("") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 display "add in week"
 
 capture noisily xtpoisson nevents ib0.vacc1_`j'_ext ib0.week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
     mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Extended risk window after 1d") ("add in week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 
 display "add in 2 week period"
 
 capture noisily xtpoisson nevents ib0.vacc1_`j'_ext ib0.two_week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
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
				

 capture noisily xtpoisson nevents ib0.vacc1_`j'_non_risk_post_vacc if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
    mat b = r(table) 
 
  forvalues v = 1/5 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Post-vacc non-risk period after 1d") ("") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 display "add in week"
 
 capture noisily xtpoisson nevents ib0.vacc1_`j'_non_risk_post_vacc ib0.week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
     mat b = r(table) 
 
  forvalues v = 1/5 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Post-vacc non-risk period after 1d") ("add in week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 


 
 display "add in 2 week period"
 
 capture noisily xtpoisson nevents ib0.vacc1_`j'_non_risk_post_vacc ib0.two_week if first_brand=="`brand'", fe i(patient_id) offset(loginterval) eform
 
      mat b = r(table) 
 
  forvalues v = 1/5 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("Post-vacc non-risk period after 1d") ("add in 2 week") ("") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 
 
 } 
 
 
 * Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary_sens_risk_`brand'", clear
export delimited using "`c(pwd)'/output/tables/results_summary_sens_risk_`brand'.csv", replace


 log close
