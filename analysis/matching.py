import pandas as pd
from osmatching import match

# AZ MATCHING 

## Match concurrent controls (assign same index date)
match(
    case_csv="input_az_cases",
    match_csv="input_controls",
    matches_per_case=10,
    match_variables={
        "age_grouped": "category",
        "stp": "category",
    },
    closest_match_variables=["age"],
    index_date_variable="first_any_vaccine_date", 
    replace_match_index_date_with_case="no_offset", 
    date_exclusion_variables={
        "death_date": "before",
        "dereg_date": "before",
        "first_any_vaccine_date": "before",
        "any_vte": "before",
    },
    indicator_variable_name="az_exposed", 
    output_suffix="_az_concurrent",
    output_path="output",
)

## Match historical controls (assign index date - 160 days)
match(
    case_csv="input_az_cases",
    match_csv="input_controls",
    matches_per_case=10,
    match_variables={
        "age_grouped": "category",
        "stp": "category",
    },
    closest_match_variables=["age"],
    index_date_variable="first_any_vaccine_date", 
    replace_match_index_date_with_case="160_days_earlier", 
    date_exclusion_variables={
        "death_date": "before",
        "dereg_date": "before",
        "first_any_vaccine_date": "before",
        "any_vte": "before",
    },
    indicator_variable_name="az_exposed", 
    output_suffix="_az_historical",
    output_path="output",
)

# PFIZER MATCHING 

## Match concurrent controls (assign same index date)
match(
    case_csv="input_pfizer_cases",
    match_csv="input_controls",
    matches_per_case=10,
    match_variables={
        "age_grouped": "category",
        "stp": "category",
    },
    closest_match_variables=["age"],
    index_date_variable="first_any_vaccine_date", 
    replace_match_index_date_with_case="no_offset", 
    date_exclusion_variables={
        "death_date": "before",
        "dereg_date": "before",
        "first_any_vaccine_date": "before",
        "any_vte": "before",
    },
    indicator_variable_name="pfizer_exposed", 
    output_suffix="_pfizer_concurrent",
    output_path="output",
)

## Match historical controls (assign index date - 160 days)
match(
    case_csv="input_pfizer_cases",
    match_csv="input_controls",
    matches_per_case=10,
    match_variables={
        "age_grouped": "category",
        "stp": "category",
    },
    closest_match_variables=["age"],
    index_date_variable="first_any_vaccine_date", 
    replace_match_index_date_with_case="160_days_earlier", 
    date_exclusion_variables={
        "death_date": "before",
        "dereg_date": "before",
        "first_any_vaccine_date": "before",
        "any_vte": "before",
    },
    indicator_variable_name="pfizer_exposed", 
    output_suffix="_pfizer_historical",
    output_path="output",
)

