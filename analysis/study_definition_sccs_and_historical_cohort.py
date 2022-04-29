# Import necessary functions
from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
    combine_codelists
)

# Import all codelists
from codelists import *

# Import Key Variables 
# These are defined in separate dictionairies (adapted from A Walker: https://github.com/opensafely/post-covid-outcomes-research/blob/master/analysis/common_variables.py)
# I've mainly used this here to improve readability and for ease of review as there are a lot of different variables extracted 

## Demographics, clinical comorbidities and comedications, included as they are potential confounders 
from confounding_variables import generate_confounding_variables
confounding_variables = generate_confounding_variables(index_date="index_date")

## Outcome variables 
from outcome_variables import generate_outcome_variables
outcome_variables = generate_outcome_variables(index_date="index_date")

## Vaccine (exposure) variables 
from vaccine_variables import generate_vaccine_variables
vaccine_variables = generate_vaccine_variables(index_date="index_date")

# Specify study definition

study = StudyDefinition(
    # configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence" : 0.2
    },

    # index date for sccs and historical cohort 
    index_date="2020-07-01", 

     # select the study population
     # note, exclusions on history of events will be applied in a dofile, as these are relevant only to specific sccs analyses
    population=patients.satisfying(
        """
        (age >= 18 AND age < 105) 
        AND 
        (sex = "M" OR sex = "F") 
        AND 
        has_baseline_time 
        AND
        known_care_home 
        AND  
        imd > 0 
        AND 
        NOT has_died 
        AND 
        NOT pregnancy 
        """,
    ),
    
    # define and select variables

    # VARIABLES NEEDED TO DEFINE INCLUSION AND EXCLUSION CRITERIA 

    ## DEMOGRAPHICS 
    ### age 
    age=patients.age_as_of(
        "2021-03-31",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    ### age group (for cohort matching)
    age_grouped= patients.categorised_as(
        {   
            "0": "DEFAULT",
            "<65": """ age < 65 """, 
            "65-69": """ age >=  65 AND age < 70""",
            "70-74": """ age >=  70 AND age < 75""",
            "75-79": """ age >=  75 AND age < 80""",
            "80+": """ age >=  80 """,
        },
        return_expectations={
            "rate":"universal",
            "category": {"ratios": {"<65":0.5, "65-69": 0.1,"70-74": 0.1, "75-79": 0.1, "80+":0.2}}
        },
    ),
    ### sex 
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),

    ## ADMINISTRATIVE VARIABLES 
    ### has one year of baseline time
    has_baseline_time=patients.registered_with_one_practice_between(
       start_date="index_date - 1 year",
       end_date="index_date",
       return_expectations={"incidence": 0.95},
    ),

    ### died before index date
    has_died=patients.died_from_any_cause(
      on_or_before="index_date",
      returning="binary_flag",
    ),

    ## RESIDENTIAL STATUS 
    ### known care home 
    #### type of care home
    care_home_type=patients.care_home_status_as_of(
        "index_date",
        categorised_as={
            "CareHome": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "NursingHome": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "CareOrNursingHome": "IsPotentialCareHome",
            "PrivateHome": "NOT IsPotentialCareHome",
            "": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"CareHome": 0.30, "NursingHome": 0.10, "CareOrNursingHome": 0.10, "PrivateHome":0.45, "":0.05},},
        },
    ),
    #### has any value for the above 
    known_care_home=patients.satisfying(
        """care_home_type""",
        return_expectations={"incidence": 0.99},
    ),

    ## PREGNANCY 
    ### pregnancy codes recorded in the 9 months before index
    pregnancy=patients.with_these_clinical_events(
        preg,
        returning="binary_flag",
        find_last_match_in_period=True,
        between=["index_date - 274 days", "index_date"],
        return_expectations={"incidence": 0.01}
    ),

    # CENSORING VARIABLES 
    ## deregistration date
    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_after="index_date", date_format="YYYY-MM-DD",
    ),

    # all-cause death (ons)
    death_date=patients.died_from_any_cause(
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "2020-07-01", "latest" : "2021-05-01"},
            "rate": "uniform",
            "incidence": 0.02
        },
    ),

    # EXPOSURE (COVID VACCINATION) VARIABLES  
    # any COVID vaccination (first dose) after index 
    **vaccine_variables, 

    # OUTCOME (VTE) VARIABLES (occuring after the index date)
    **outcome_variables, 

    # CLINICAL COMORBIDITIES (note: includes history of some outcomes used as exclusion criteria in individual SCCS cohorts)
    **confounding_variables, 

    ## Pregnancy Outcomes (TBD coding)

) 












