/*==============================================================================
DO FILE NAME:			SCCS_first_dose_only_analyses_sens_AZ_vs_PF.do
PROJECT:				Vaccine Safety  
DATE: 					3rd Sept 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS analysis of neuro events (GBS, TM and BP) - ratio of ratios AZ vs PF
							
DATASETS USED:			sccs_cutp_data_BP_AZ.dta, sccs_cutp_data_TM_AZ.dta ,sccs_cutp_data_GBS_AZ.dta
						sccs_cutp_data_BP_PF.dta, sccs_cutp_data_TM_PF.dta ,sccs_cutp_data_GBS_PF.dta
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfile, printed to folder /logs
						tables- results_summary_sens_AZ_vs_PF, printed to folder /tables
						
							
==============================================================================*/

/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"
capture	mkdir "`c(pwd)'/output/tables"
capture	mkdir "`c(pwd)'/output/temp_data"

* set ado path
adopath + "`c(pwd)'/analysis/extra_ados"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_first_dose_only_sens_AZ_vs_PF.log", replace 

/* ANALYSIS===================================================================*/

* Setup file for posting results
  tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_sens_AZ_vs_PF", replace
		
foreach j in BP TM GBS{
	
use "`c(pwd)'/output/temp_data/sccs_cutp_data_`j'_AZ.dta", clear
append using "`c(pwd)'/output/temp_data/sccs_cutp_data_`j'_PF.dta"
 
*need numeric variable for interaction term for ratio of ratios- AZ vs PF 
gen AZ=1 if first_brand=="AZ"
recode AZ .=0 

 tempname results
	postfile `results' ///
		str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
		using "`c(pwd)'/output/tables/results_summary_sens_AZ_vs_PF", replace
 
 *head to head comparison- AZ vs PF
 display "****************"
 display "****OUTCOME*****"
 display "`j'"
 display "****************"
 display "AZ VS PF PRIMARY RISK WINDOW AFTER 1ST DOSE"
 *vacc1 has 5 levels, non-risk - baseline (0), pre-vacc low 28 days -TM, GBS /14 days BP (1), day 0 (2) days 1-3 (3) and days 4-28 BP, TM / 4-42 GBS (4)
  
 **IF DOSES >1JAN  (incl_AZ_PF_compare==1)
 
 *need originals to comapre to limited to >1st Jan as well
 
 di "`j' AZ (RESTRICTED TO DOSES AFTER 1st JAN)"
 
 xtpoisson nevents ib0.vacc1_`j' if first_brand=="AZ" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   if _rc==0{
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("") ("First = AZ") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 else di "DID NOT CONVERGE - `j' AZ (RESTRICTED TO DOSES AFTER 1st JAN)"
 

 di "`j' PF (RESTRICTED TO DOSES AFTER 1st JAN)"
 xtpoisson nevents ib0.vacc1_`j' if first_brand=="PF" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
   
   if _rc==0{
  mat b = r(table) 
 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("") ("First = PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	}

	 else di "DID NOT CONVERGE - `j' PF (RESTRICTED TO DOSES AFTER 1st JAN)"
 
 
 di " `j' AZ VS PF"
 xtpoisson nevents ib0.vacc1_`j'##AZ if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform

     if _rc==0{
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 10 + (`v'-1) 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("") ("AZ vs PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	}
else di "DID NOT CONVERGE - `j' AZ VS PF"
 
 
 display "ADD IN WEEK PERIOD"
 
 di "`j' AZ (RESTRICTED TO DOSES AFTER 1st JAN) - WEEK ADJ"
 xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="AZ" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
  
    if _rc==0{
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in week") ("First = AZ") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	}
 else di "DID NOT CONVERGE - `j' AZ (RESTRICTED TO DOSES AFTER 1st JAN) - WEEK ADJ"
	
 di "`j' PF (RESTRICTED TO DOSES AFTER 1st JAN) - WEEK ADJ"
 xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="PF" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   if _rc==0{
  mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in week") ("First = PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 else di "DID NOT CONVERGE - `j' PF (RESTRICTED TO DOSES AFTER 1st JAN) - WEEK ADJ"

 
 di "`j' AZ VS PF -  WEEK ADJ "
  xtpoisson nevents ib0.vacc1_`j'##AZ ib0.week if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   if _rc==0{
    mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 10 + (`v'-1) 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in week") ("AZ vs PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
	}
 else di "DID NOT CONVERGE - `j' AZ VS PF -  WEEK ADJ "
 
  
  di "`j' AZ VS PF -  WEEK ADJ & INTERACTION"
  xtpoisson nevents ib0.vacc1_`j'##AZ ib0.week##AZ if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   if _rc==0{
     mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 10 + (`v'-1) 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in week interction") ("AZ vs PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 
 else di "DID NOT CONVERGE - `j' AZ VS PF -  WEEK ADJ & INTERACTION"
 
 
 display "ADD IN 2 WEEK PERIOD"
 
 di "`j' AZ (RESTRICTED TO DOSES AFTER 1st JAN) - 2 WEEK ADJ"
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="AZ" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   if _rc==0{
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in 2 week") ("First = AZ") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 
  else di "DID NOT CONVERGE - `j' AZ (RESTRICTED TO DOSES AFTER 1st JAN) - 2 WEEK ADJ"

 di "`j' PF (RESTRICTED TO DOSES AFTER 1st JAN) -2 WEEK ADJ"
 xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="PF" & incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
   if _rc==0{
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 1 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in 2 week") ("First = PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
  else di "DID NOT CONVERGE - `j' PF (RESTRICTED TO DOSES AFTER 1st JAN) -2 WEEK ADJ"

  
 di "`j' AZ VS PF - 2 WEEK ADJ "
 xtpoisson nevents ib0.vacc1_`j'##AZ ib0.two_week if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
     if _rc==0{
   mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 10 + (`v'-1) 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in 2 week") ("AZ vs PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
 else di "DID NOT CONVERGE - `j' AZ VS PF - 2 WEEK ADJ "
 
 di "`j' AZ VS PF - 2 WEEK ADJ & INTERACTION"
  xtpoisson nevents ib0.vacc1_`j'##AZ ib0.two_week##AZ if incl_AZ_PF_compare==1, fe i(patient_id) offset(loginterval) eform
 
      if _rc==0{
	mat b = r(table) 
 
  forvalues v = 1/4 {
    local k = `v' + 10 + (`v'-1) 
	post `results'  ("`j'") ("`brand'") ("AZ vs PF primary risk window") ("add in 2 week interction") ("AZ vs PF") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
	}
 }
  else di "DID NOT CONVERGE - `j' AZ VS PF - 2 WEEK ADJ & INTERACTION"
 

 }
 
* Close post-file
postclose `results'

use "`c(pwd)'/output/tables/results_summary_sens_AZ_vs_PF", clear
export delimited using "`c(pwd)'/output/tables/results_summary_sens_AZ_vs_PF.csv", replace
 
log close 
 
