/*==============================================================================
DO FILE NAME:			SCCS_assumption_checking.do
PROJECT:				Vaccine Safety  
DATE: 					28 June 2021  
AUTHOR:					A Schultze 
								
DESCRIPTION OF FILE:	generates exposure-centered interval plot 
						generates table of deaths within X days of each outcome 
						
DATASETS USED:			sccs_popn_BP.dta, sccs_popn_TM.dta, sccs_popn_GBS.dta, from /tempdata
DATASETS CREATED: 		svg and txt files per outcome and vaccine brand as per project.yaml, into /tables
						have to be manually appended 
OTHER OUTPUT: 			logfile, printed to folder /logut/logs 
							
==============================================================================*/

/* HOUSEKEEPING===============================================================*/

* create folders that do not exist on server 
capture	mkdir "`c(pwd)'/output/logs"
capture	mkdir "`c(pwd)'/output/plots"
capture	mkdir "`c(pwd)'/output/tables"

* set ado path
adopath + "$projectdir/analysis/extra_ados"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_assumption_checking.log", replace 

* IMPORT AND CLEAN DATA=======================================================*/ 
* basic data management to generate FU time and count deaths occuring after each event 

foreach outcome in GBS TM BP { 

	use `c(pwd)'/output/temp_data/sccs_popn_`outcome', clear
	
	* convert required string variables to date 
	foreach var of varlist censor_date ///
						   death_date { 
					   	
						capture confirm string variable `var'
						if _rc == 0 { 
							rename `var' _tmp
							gen `var' = date(_tmp, "YMD")
							drop _tmp
							format %d `var'
						}
					   }
	
	** Censoring  
	* censor date for each specific outcome (only exists as days, not dates in file)
	gen first_censor_`outcome' = min(censor_date, censor_date_`outcome')
	* indicator for planned censoring vs. not 
	gen early_censoring=(calendar_censor_date != first_censor_`outcome')
	label define early_censoring 0 "Planned Censoring" 1 "Early Censoring"
	label values early_censoring early_censoring 
	* time to actual study end 
	gen time_to_`outcome'_end = first_censor_`outcome' - `outcome' 
	* time to outcome 
	gen time_to_`outcome' = eventday - vacc_date1
	
	** Death 	
	gen death_after_`outcome' = 1 if death_date != . & death_date <= first_censor_`outcome' & ((death_date - `outcome') < 42)
	replace death_after_`outcome' = 0 if death_after_`outcome' == . 

/* GENERATE PLOTS AND TABLES==================================================*/ 

	foreach brand in AZ PF MOD {
		
		preserve 
		drop if first_brand != "`brand'"
	
		noi di ""
		noi di "===OUTPUT START:`brand' `outcome' case series==="
		noi di ""
		
		* gen variable for redaction limits 
		gen max_y = 5
	
		** EXPOSURE CENTERED INTERVAL PLOT 
		
		* generate x-axis limits and cut-off count for redaction 
		twoway__histogram_gen time_to_`outcome', freq gen(count where)
		egen lowest_count = min(count)
		if lowest_count <= 5 {
		
			noi di "THE EXPOSURE CENTERED INTERVAL PLOT FOR `brand' `outcome' CONTAINS BINS OF FREQUENCIES < 5 AND HAS BEEN REDACTED"
			
			* plot with redaction and output as pdf - note, cannot be vector quality due to disclosivity risk 
			* note jpeg/png export not compatible with linux, will be converted using another script 
			twoway histogram time_to_`outcome', frequency /// 
				graphregion(color(white)) ///
				bcolor(emidblue) fcolor(ebg)    ///
				ytitle("Count") xtitle("Time between first `brand' dose and `outcome', days") ///
				|| area max_y time_to_`outcome', sort color(gray) legend(order(1 "Frequency" 2 "Redacted"))
								   
			graph export "output/plots/S1_exposure_centered_interval_`brand'_`outcome'.pdf", as(pdf) replace
			graph close	
		
		} 
		
		else if lowest_count > 5 { 
				
			* plot without redaction and output as svg - vector image with higher quality 
			twoway histogram time_to_`outcome', frequency /// 
				graphregion(color(white)) ///
				bcolor(emidblue) fcolor(ebg)    ///
				ytitle("Count") xtitle("Time between first `brand' dose and `outcome', days") 
								   
			graph export "output/plots/S1_exposure_centered_interval_`brand'_`outcome'.svg", as(svg) replace
			graph close	
			
		}
		
		* drop variables used for redaction purposes only so these can be recalculated for other plots 
		drop count where lowest_count 
		
		* EVENT DEPENDENT CENSORING PLOTS 

		twoway__histogram_gen time_to_`outcome'_end if early_censoring == 1 , freq gen(count where)
		egen lowest_count1 = min(count)
		drop count where 
		
		twoway__histogram_gen time_to_`outcome'_end if early_censoring == 0 , freq gen(count where)
		egen lowest_count0 = min(count)
		
		gen lowest_count = min(lowest_count0, lowest_count1)
		
		if lowest_count <= 5 {
			
			noi di "THE EVENT DEPENDENT CENSORING PLOT FOR `brand' `outcome' CONTAINS BINS OF FREQUENCIES < 5 AND HAS BEEN REDACTED"
			
			* plot with redaction and output as pdf - note - highly sensitive due to raw code, will be converted to jpg 
			twoway histogram time_to_`outcome'_end if early_censoring == 0, by(early_censoring, note(" ") legend(off) graphregion(color(white))) ///
				bcolor(emidblue) fcolor(ebg) ///
			    frequency /// 
			    || histogram time_to_`outcome'_end if early_censoring == 1,  ///
			    bcolor(maroon) fcolor(erose) ///
			    frequency /// 
			    ytitle("Count") xtitle("Time between `outcome' and study end in `brand' case series, days") ///
				|| area max_y time_to_`outcome'_end, sort color(gray) legend(order(1 "Frequency" 2 "Redacted"))
			   
			graph export "output/plots/S2_censored_futime_`brand'_`outcome'.pdf", as(pdf) replace
			graph close
		
		} 
		
		else if lowest_count > 5 {

			* plot without redaction and output as svg - vector image with higher quality 
			twoway histogram time_to_`outcome'_end if early_censoring == 0, by(early_censoring, note(" ") legend(off) graphregion(color(white))) ///
			    bcolor(emidblue) fcolor(ebg) ///
			    frequency /// 
			    || histogram time_to_`outcome'_end if early_censoring == 1,  ///
			    bcolor(maroon) fcolor(erose) ///
			    frequency /// 
			    ytitle("Count") xtitle("Time between `outcome' and study end in `brand' case series, days") 
			   
			graph export "output/plots/S2_censored_futime_`brand'_`outcome'.svg", as(svg) replace
			graph close
		
		} 
  
		 
		* DEATHS WITHIN 42 DAYS OF THE OUTCOME, TABULATION 
		noi di ""
		noi di "DEATHS WITHIN 42 DAYS OF `outcome' in the `brand' case series"
		noi di "" 
		
		safetab death_after_`outcome' 
		
		restore 
		
	} 
	
} 
			   
* CLOSE LOG===================================================================*/ 

log close
