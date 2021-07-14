from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


def generate_hospital_admission_variables(index_date):
    hospital_admission_variables = dict(

    # Time-updated admission dates
    ## Extracted monthly, variable indicating 'admission in the 3 months before the 1st of this month of FU'    
    ## So admitted_1 is admission in 3 months before 1st of July 2020 
    ## admitted_2 is admission in 3 months before 1st of August 2020, etc until 1st of March 2021 (end of FU 11th of March 2021)

    ### all admissions 
    admitted_1=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date", "index_date - 3 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_2=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 1 months", "index_date - 2 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_3=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 2 months", "index_date - 1 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_4=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 3 months", "index_date"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_5=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 4 months", "index_date + 1 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_6=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 5 months", "index_date + 2 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_7=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 6 months", "index_date + 3 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_8=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 7 months", "index_date + 4 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_9=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 8 months", "index_date + 5 months"],
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),


    ### infectious admissions only 
    admitted_inf_1=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date", "index_date - 3 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_2=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 1 months", "index_date - 2 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_3=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 2 months", "index_date - 1 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_4=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 3 months", "index_date"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_5=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 4 months", "index_date + 1 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_6=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 5 months", "index_date + 2 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_7=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 6 months", "index_date + 3 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_8=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 7 months", "index_date + 4 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    admitted_inf_9=patients.admitted_to_hospital(
        returning="binary_flag",
        between=["index_date + 8 months", "index_date + 5 months"],
        with_these_diagnoses = ICD10_I_codes,
        with_patient_classification = ["1"],
        find_last_match_in_period=True,
        return_expectations={"incidence": 0.10},
    ),

    )
    return hospital_admission_variables 
