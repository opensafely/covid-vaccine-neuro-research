/*==============================================================================
DO FILE NAME:			SCCS_neuro_attributable.do
PROJECT:				Vaccine Safety  
DATE: 					17th May 2022- updated after reviewers comments  
AUTHOR:					Jemma Walker
								
DESCRIPTION OF FILE:	Calculate attributable risk by brand of vaccine and outcome
							
							

DATASETS USED:			
DATASETS CREATED: 		
						
						
						
OTHER OUTPUT: 			
						
							
==============================================================================*/

******************************************
**ATTRIBUTABLE RISK FORMULA **************
******************************************

*(((IRR-1)/IRR) x number in risk window )/ number of first doses


clear
set obs 1
generate num = 1 in 1



*number of first doses (number vaccinated)

gen dose_AZ=7783441 if num==1
gen dose_PF=5729152 if num==1
gen dose_MOD=255446 if num==1



******UPDATE THESE TO REAL NUMBERS*******
*number of cases in risk window for each outcome/brand


gen num_case_AZ_BP=497 if num==1

gen num_case_AZ_GBS=132 if num==1



*IRR for each outcome/ brand
gen IRR_AZ_BP=1.39 if num==1
gen IRR_AZ_GBS=2.85 if num==1



foreach i in AZ  {

foreach j in BP  GBS {


gen attr_`i'_`j'=IRR_`i'_`j'-1  if num==1
replace attr_`i'_`j'=attr_`i'_`j'/IRR_`i'_`j' if num==1
replace attr_`i'_`j'=attr_`i'_`j' * num_case_`i'_`j' if num==1
replace attr_`i'_`j'=attr_`i'_`j'/dose_`i'

}

}

display "ATTRIBUTABLE RISK AZ BP AS % OF DOSES GIVEN"
display attr_AZ_BP[1] * 100

display "ATTRIBUTABLE RISK AZ GBS  AS % OF DOSES GIVEN"
display attr_AZ_GBS[1] * 100

display "NUMBER VACCINES GIVEN FOR ONE ATTRIBUTABLE CASE AZ BP "
display 1/attr_AZ_BP[1]

display "NUMBER VACCINES GIVEN FOR ONE ATTRIBUTABLE CASE AZ GBS"
display 1/attr_AZ_GBS[1]





