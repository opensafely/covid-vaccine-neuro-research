/*==============================================================================
DO FILE NAME:			SCCS_baseline_tables 
PROJECT:				Vaccine Safety  
DATE: 					19th Aug 2021  
AUTHOR:					Anna Schultze
								
DESCRIPTION OF FILE:	Print basic characteristics for each SCCS and vaccine brand 

DATASETS USED:			sccs_popn_BP.dta, sccs_popn_TM.dta, sccs_popn_GBS.dta, from /tempdata
DATASETS CREATED: 		txt file per outcome and vaccine brand as per project.yaml, into /tables
						have to be manually appended 
OTHER OUTPUT: 			logfile, printed to folder /log
							
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
capture	mkdir "`c(pwd)'/output/tables/baseline_`brand'"

* open a log file
cap log close
log using "`c(pwd)'/output/logs/SCCS_baseline_tables_`brand'.log", replace 

/* PROGRAMS TO AUTOMATE TABULATIONS===========================================*/ 
********************************************************************************
* assumes variables have both variable and value labels 

* Generate one row for a categorical variable 
/* Explanatory Notes 
the syntax row specifies two inputs for the program: 
	a VARNAME which is your variable that you would like to tabulate, stratified 
	by the exposure 
	a LEVEL which is only used to extract a value label to print 
	a CONDITION which is a string of some condition you impose 
	
the program counts if variable and condition and returns the counts
column percentages are then automatically generated
this is then written to the text file 'tablecontent' 

*/ 

cap prog drop generaterow
program define generaterow
syntax, variable(varname) [level(string)] condition(string) 

	* indent extra if the level is not 1 (assumed first value)
	if ("`level'" != "1") {
		file write tablecontent _tab
	} 
	
	* print a value label at beginning of row 
	if ("`level'" != "") { 
		local vlab: label `variable' `level'
		file write tablecontent ("`vlab'") _tab 
	}
	else {
		file write tablecontent ("Missing") _tab
	}
	
	* create denominator and print total 
	qui count
	local overalldenom=r(N)
	
	* total column
	qui count if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %15.0gc (`rowdenom')  (" (") %3.2f (`colpct') (")") _n

end

* Generate all rows for a categorical variable with multiple levels (calls above)

/* Explanatory Notes 
defines program tabulate variable 
syntax is : 

	- a VARNAME which is your variable of interest 
	- a numeric minimum (min value of your variable you want to tabulate)
	- a numeric maximum (max value of your variable you want to tabulate)
	- optional missing option, default value is no missing  
	
for values lowest to highest of the variable, the program then calls the 
generate row program defined above to generate a row 
if there is a missing specified, then run the generate row for missing vals
*/ 

cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) min(real) max(real) [missing]
	
	local lab: variable label `variable'
	file write tablecontent ("`lab'") _tab 

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') level(`varlevel') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.")

end

* Summarise a continous variable 

cap prog drop summarizevariable 
prog define summarizevariable
syntax, variable(varname) 

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _tab
	
	qui summarize `variable', d
	file write tablecontent ("Median (IQR)") _tab 
	file write tablecontent (round(r(p50)),0.01) (" (") (round(r(p25)),0.01) ("-") (round(r(p75)),0.01) (")") _n
							
	qui summarize `variable', d
	file write tablecontent _tab ("Min, Max") _tab 
	file write tablecontent (round(r(min)),0.01) (", ") (round(r(max)),0.01) ("") _n
							
end

* IMPORT DATA=================================================================*/ 
* This is currently set up in a loop per outcome, reading in each brand from the yaml 

foreach outcome in GBS TM BP { 

	use `c(pwd)'/output/temp_data/sccs_popn_`outcome'_`brand', clear

	** Basic data management and adding labels
	** Note label name needs to match var name for automatic printing to work 
	
	* Gender
	gen gender = 1 if sex == "M"
	replace gender = 2 if sex == "F"
	label define gender 1 "Men" 2 "Women" 
	label values gender gender 
	
	* Age group (from string to categorical with labs)
	gen age_group_format = 1 if age_group_SCCS == "18-39"
	replace age_group_format = 2 if age_group_SCCS == "40-64"
	replace age_group_format = 3 if age_group_SCCS == "65-105"
	label define age_group_format 1 "18-39" 2 "40-64" 3 "65-105"
	label values age_group_format age_group_format 
	
	* Care Home Residency 
	datacheck inlist(care_home_type, "CareHome", "NursingHome", "CareOrNursingHome", "PrivateHome", "")

	gen care_home = 1 if care_home_type == "PrivateHome"
	replace care_home = 2 if care_home_type == "CareHome"  
	replace care_home = 3 if care_home_type == "NursingHome"  
	replace care_home = 4 if care_home_type == "CareOrNursingHome"  
	replace care_home = .u if care_home >= .  

	label define care_home 4 "Care or Nursing Home" 3 "Nursing Home" 2 "Care Home" 1 "Private Home" .u "Missing"
	label values care_home care_home 
	
	* Outcome Event 
	gen sccs_outcome_`outcome' = (`outcome' != .) 
	label define sccs_outcome_`outcome' 1 "" 
	label values sccs_outcome_`outcome' sccs_outcome_`outcome'
	
	* Prior COVID 
	replace prior_covid = 0 if prior_covid == . 
	label define prior_covid 1 ""
	label values prior_covid prior_covid 
	
	* HCW 
	label define hcw 1 ""
	label values hcw hcw 
	
	* outcome in different settings
	* note: for each outcome because of naming changes in prior do-file compared to python 
	
	* convert each string to a date 
	generate BP_GP = bells_palsy_gp
	generate BP_hospital = bells_palsy_hospital 
	generate BP_death = bells_palsy_death
	generate BP_emergency = bells_palsy_emergency 
	
	generate TM_GP = transverse_myelitis_gp
	generate TM_hospital = transverse_myelitis_hospital 
	generate TM_death = transverse_myelitis_death
	
	generate GBS_GP = guillain_barre_gp
	generate GBS_hospital = guillain_barre_hospital 
	generate GBS_death = guillain_barre_death
	
	foreach var of varlist `outcome'_GP ///
						   `outcome'_hospital  ///
						   `outcome'_death { 
					   	
						capture confirm string variable `var'
						if _rc == 0 { 
							rename `var' _tmp
							gen `var' = date(_tmp, "YMD")
							drop _tmp
							format %d `var'
						}
					  }

	* create indicator variables each outcome 
	foreach var of varlist `outcome'_GP ///
						   `outcome'_hospital  ///
						   `outcome'_death { 
						   	
								gen `var'_ind = (`var' != .)
								* empty labels to display just variable name in table  
								label define `var'_ind 1 ""
								label values `var'_ind `var'_ind 
							
						   } 
						   
	* specific consideration for emergency codes 
	if "`outcome'" == "BP" { 
		
		rename BP_emergency _tmp 
		gen BP_emergency = date(_tmp, "YMD")
		drop _tmp
		format BP_emergency %d 
		
		gen BP_emergency_ind = (BP_emergency != .)
		label define BP_emergency_ind 1 ""
		label values BP_emergency_ind BP_emergency__ind 
		
		label variable BP_emergency_ind "Diagnosed in A&E"
		
		} 
		
	else di "BP outcomes are not relevant to this case series, variables not created"
	
	* create variables for recording in more than one setting (each person one category only)
	* ignore emergency codes for BP for now 
		
	gen `outcome'_location = "GP only" if `outcome'_GP_ind == 1 & /// 
										  `outcome'_hospital_ind == 0 & /// 
							              `outcome'_death_ind == 0 
								 
	replace `outcome'_location = "Hospital only" if `outcome'_GP_ind == 0 & /// 
													`outcome'_hospital_ind == 1 & /// 
													`outcome'_death_ind == 0 						 
								 
	replace `outcome'_location = "Death only" if `outcome'_GP_ind == 0 & /// 
												 `outcome'_hospital_ind == 0 & /// 
												 `outcome'_death_ind == 1 			
								 
	replace `outcome'_location = "GP and hospital" if `outcome'_GP_ind == 1 & /// 
													  `outcome'_hospital_ind == 1 & /// 
													  `outcome'_death_ind == 0 	
									 
	replace `outcome'_location = "Hospital and death" if `outcome'_GP_ind == 0 & /// 
														 `outcome'_hospital_ind == 1 & /// 
														 `outcome'_death_ind == 1 		
									  
	replace `outcome'_location = "GP and death" if `outcome'_GP_ind == 1 & /// 
												   `outcome'_hospital_ind == 0 & /// 
												   `outcome'_death_ind == 1 		
									  
	replace `outcome'_location = "GP and hospital and death" if `outcome'_GP_ind == 1 & /// 
																`outcome'_hospital_ind == 1 & /// 
																`outcome'_death_ind == 1 
									  
	* separate consideration for how emergency codes adds on to this 
	
	if "`outcome'" == "BP" { 
		
		replace `outcome'_location = "GP and emergency" if `outcome'_location == "GP only" & `outcome'_emergency_ind == 1 
		replace `outcome'_location = "Hospital and emergency" if `outcome'_location == "Emergency only" & `outcome'_emergency_ind == 1 
		replace `outcome'_location = "Death and emergency" if `outcome'_location == "Death only" & `outcome'_emergency_ind == 1 
		
		replace `outcome'_location = "GP and hospital and emergency" if `outcome'_location == "GP and hospital" & `outcome'_emergency_ind == 1 
		replace `outcome'_location = "GP and death and emergency" if `outcome'_location == "GP and death" & `outcome'_emergency_ind == 1 
		replace `outcome'_location = "Hospital and death and emergency" if `outcome'_location == "Hospital and death" & `outcome'_emergency_ind == 1 
		
		replace `outcome'_location = "GP and hospital and death and emergency" if `outcome'_location == "GP and hospital and death" & `outcome'_emergency_ind == 1 

		
	}
	
	else di "BP outcomes are not relevant to this case series, variables not created"
	
	* Tab diagnosis location (unique) note not safetab as need to see recording and log will not be released 
	
	tab `outcome'_location, m

	** Add variable and value labels to variables that you want to present in tables 
	label variable sccs_outcome "Total Cases"
	label variable age_group_format "Age Group"
	label variable age "Age"
	label variable gender "Gender"
	label variable care_home "Care Home"
	label variable hcw "Health Care Worker"
	label variable prior_covid "Prior Covid"
	label variable `outcome'_GP_ind "Diagnosed at GP"
	label variable `outcome'_hospital_ind "Diagnosed at Hospital"
	label variable `outcome'_death_ind "Diagnosed at Death"
	
/* INVOKE PROGRAMS FOR TABLE 1================================================*/ 
* include cross tabs in log for QC 
* this is done in a loop for vaccine brand as assumed not computationally intensive 

	* Print info to log 
		
	noi di ""
	noi di "===OUTPUT START:`brand' `outcome' case series==="
	noi di ""
	
	count if sccs_outcome_`outcome'
	if r(N) > 5 {

	*Set up output file
	cap file close tablecontent
	file open tablecontent using `c(pwd)'/output/tables/1_baseline_`brand'/table1_`brand'_`outcome'.txt, write text replace

	file write tablecontent ("Table 1: Demographics of individuals in the `brand' `outcome' case series") _n

	* Column headings 
	file write tablecontent _tab _tab  ("`outcome'") _n
	file write tablecontent _tab _tab  ("N (%)") _n

	* DEMOGRAPHICS (more than one level, potentially missing) 

	* count of cases
	tabulatevariable, variable(sccs_outcome_`outcome') min(1) max(1) 
	file write tablecontent _n 
	safetab sccs_outcome, m

	summarizevariable, variable(age)
	file write tablecontent _n 
	summarize age, d 

	tabulatevariable, variable(age_group_format) min(1) max(3) missing
	file write tablecontent _n 
	safetab age_group_format, m

	tabulatevariable, variable(gender) min(1) max(2) missing 
	file write tablecontent _n 
	safetab gender, m

	tabulatevariable, variable(prior_covid) min(1) max(1) 
	file write tablecontent _n 
	safetab prior_covid, m
	
	tabulatevariable, variable(`outcome'_GP_ind) min(1) max(1) 
	file write tablecontent _n 
	safetab `outcome'_GP_ind, m
	
	tabulatevariable, variable(`outcome'_hospital_ind) min(1) max(1) 
	file write tablecontent _n 
	safetab `outcome'_hospital_ind, m
	
	tabulatevariable, variable(`outcome'_death_ind) min(1) max(1) 
	file write tablecontent _n 
	safetab `outcome'_death_ind, m
	
	* add BP emergency codes (only one outcome)
	
	if "`outcome'" == "BP" {

		tabulatevariable, variable(`outcome'_emergency_ind) min(1) max(1) 
		file write tablecontent _n 
		safetab `outcome'_emergency_ind, m
			
	}

	file close tablecontent
	
	} 
	
	else di "5 or fewer outcomes, no table generated"

}

/* PLOT OUTCOMES OVER TIME BY LOCATION OF CODING =============================*/
* for sense checking 



	
* Close log file 
log close
