/*==============================================================================
DO FILE NAME:			SCCS_first_dose_only_analyses_neuro_sens_stratified.do
PROJECT:				Vaccine Safety  
DATE: 					3rd Sept 2021  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	SCCS sensitivity analyses of neuro events - GBS, TM and BP
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
local brand = "AZ"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_first_dose_only_analyses_neuro_sens_stratified_`brand'.log", replace 


/* PROGRAMS TO AUTOMATE MODELS================================================*/ 
* Fit unadjusted, adjusted 1 week and adjusted 2 week models with a condition 

/* Explanatory Notes 
the syntax row specifies inputs for the program: 
	
	brand which is the brand we want the program to see (defined in loop)
	j which is the outcome loop position we want the program to see (defined in loop)
	results which is the name of your results file (defined in loop)
	strat_var which is the stratification var 
	strat_level_num which is the stratification level you're interested in if numeric
	strat_level_string which is the stratification level you're interested in if string
	
in reality there are more local macros supplied to the program, from the yaml 
and the loop. there are also some inefficencies in the programs, of particular note 
is hacky workaround to differentiate string and numeric inputs, 
given that the numeric  actually needs to be a string... 
*/ 

cap prog drop fitmodels
program define fitmodels
syntax, brand(string) j(string) results(string) strat_var(string) [strat_level_string(string)] [strat_level_num(string)]

	
	 capture confirm number `=strat_level_num'
	 di _rc 
	 if _rc == 0 { 
	 	local condition = "`strat_var'==`strat_level_num'"
	 }
	 else {
	 	local condition = "`strat_var'==`"`strat_level_string'"'"
	 }
	 
	 di "`condition'"
	 
	 * display key information 
	 display "****************"
	 display "****OUTCOME*****"
	 display "`j'"
	 display "****************"
	 display "`brand' PRIMARY RISK WINDOW AFTER 1ST DOSE"
	 display "STRATIFIED BY `strat_var'"

	 * unadjusted models 
	 display "`strat_level_string'`strat_level_num'"
	 display "UNADJUSTED"
	 capture noisily xtpoisson nevents ib0.vacc1_`j'  if first_brand=="`brand'" & `condition', fe i(patient_id) offset(loginterval) eform
	 
	 * if no error message and convergence status is 1 (statement below evaluates to false, i.e, 0)
	 if _rc+(e(converge)==0) == 0 {
		mat b = r(table) 
	 
		forvalues v = 1/4 {
			local k = `v' + 1 
			post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("") ("`strat_level_string'`strat_level_num") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	  }
	  
	 * adjusted models, one week
	 display "ADD IN WEEK PERIOD"
	 capture noisily xtpoisson nevents ib0.vacc1_`j' ib0.week if first_brand=="`brand'" & `condition', fe i(patient_id) offset(loginterval) eform
	   
	 if _rc+(e(converge)==0) == 0 { 
		mat b = r(table) 
	 
		forvalues v = 1/4 {
			local k = `v' + 1 
			post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in week") ("`strat_level_string'`strat_level_num") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	  } 
	 
	 *adjusted models, two weeks 
	 display "ADD IN 2 WEEK PERIOD"
	 capture noisily xtpoisson nevents ib0.vacc1_`j' ib0.two_week if first_brand=="`brand'" & `condition', fe i(patient_id) offset(loginterval) eform
	 
	 if _rc+(e(converge)==0) == 0 { 
		mat b = r(table) 
	 
		forvalues v = 1/4 {
			local k = `v' + 1 
			post `results'  ("`j'") ("`brand'") ("Primary risk window after 1d") ("add in 2 week") ("`strat_level_string'`strat_level_num'") (`v') (b[1,`k']) (b[5,`k']) (b[6,`k'])	
		}
	 } 
 
end


/* ANALYSIS===================================================================*/
* Setup file for posting results
tempname results
postfile `results' ///
 str4(outcome) str10(brand) str50(analysis) str35(subanalysis) str20(category) comparison_period irr lc uc ///
 using "`c(pwd)'/output/tables/results_summary_stratified_`brand'", replace
 
foreach j in BP {
	
	use "`c(pwd)'/output/temp_data/sccs_cutp_data_`j'_`brand'.dta", clear 
 
	* Age 
	fitmodels, brand(`brand') j(`j') results(`results') strat_var("age_group_SCCS") strat_level_string("18-39") 
	
	* HCW 
	fitmodels, brand(`brand') j(`j') results(`results') strat_var("hcw") strat_level_num("0") 


}

 * Close post-file
postclose `results'

* Clean and export .csv of results
use "`c(pwd)'/output/tables/results_summary_stratified_`brand'", clear
export delimited using "`c(pwd)'/output/tables/results_summary_stratified_`brand'.csv", replace

* close log 
log close
 
