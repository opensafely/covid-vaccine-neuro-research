from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


def generate_confounding_variables(index_date):
    confounding_variables = dict(
    # DEMOGRAPHICS AND LIFESTYLE 
    ## self-reported ethnicity 
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.5, "2": 0.2, "3": 0.1, "4": 0.1, "5": 0.1}},
            "incidence": 0.75,
        },
    ), 
    # smoking 
    smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                 most_recent_smoking_code = 'E' OR (
                   most_recent_smoking_code = 'N' AND ever_smoked
                 )
            """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            smoking_clear,
            find_last_match_in_period=True,
            on_or_before="index_date",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(smoking_clear, include=["S", "E"]),
            on_or_before="index_date",
        ),
    ),
    smoking_status_date=patients.with_these_clinical_events(
        smoking_clear,
        on_or_before="index_date",
        return_last_date_in_period=True,
        include_month=True,
    ),
    # GEOGRAPHICAL VARIABLES 
    ## index of multiple deprivation, estimate of SES based on patient post code 
    imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=1 AND index_of_multiple_deprivation < 32844*1/5""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation < 32844""",
        },
        index_of_multiple_deprivation=patients.address_as_of(
            "index_date",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.05,
                    "1": 0.19,
                    "2": 0.19,
                    "3": 0.19,
                    "4": 0.19,
                    "5": 0.19,
                }
            },
        },
    ),

    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),
    # CLINICAL COMORBIDITIES 
    ## history of VTE prior to 1 July 2019 (other patients excluded)
    history_any_vte_gp=patients.with_these_clinical_events(
        vte_codes_primary_care,
        on_or_before="2019-07-01", 
        returning="binary_flag",
        return_expectations={"incidence": 0.15},
    ),
    history_any_vte_hospital=patients.admitted_to_hospital(
        with_these_diagnoses=vte_codes_secondary_care,
        on_or_before="2019-07-01", 
        returning="binary_flag",
        return_expectations={"incidence": 0.10},
    ),
    history_any_vte=patients.satisfying("prior_any_vte_gp OR prior_any_vte_hospital"),

    ## variabels to define ckd 
    ### creatinine 
    creatinine=patients.with_these_clinical_events(
        creatinine_codes,
        find_last_match_in_period=True,
        between=["index_date - 1 year", "index_date"],
        returning="numeric_value",
        include_date_of_match=False,
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "date": {"earliest": "index_date - 1 year", "latest": "index_date"},
            "incidence": 0.95,
        },
    ),
    ### end stage renal disease codes incl. dialysis / transplant
    esrf=patients.with_these_clinical_events(
        chronic_kidney_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.04},
    ),

    ## cancer 
    ### haematological 
    haem_cancer_date=patients.with_these_clinical_events(
        haemtological_cancer,
        on_or_before="index_date",
        find_first_match_in_period="true", 
        returning="date",
        date_format="YYYY-MM", 
        return_expectations={"date": {"latest": "index_date"}},
    ),
    ### non-haematological 
    nonhaem_nonlung_cancer_date=patients.with_these_clinical_events(
        cancer_excluding_lung_and_haematological,
        on_or_before="index_date",
        find_first_match_in_period="true", 
        returning="date",
        date_format="YYYY-MM", 
        return_expectations={"date": {"latest": "index_date"}},
    ),
    ### non-haematological 
    lung_cancer_date=patients.with_these_clinical_events(
        lung_cancer,
        on_or_before="index_date",
        find_first_match_in_period="true", 
        returning="date",
        date_format="YYYY-MM", 
        return_expectations={"date": {"latest": "index_date"}},
    ),
    ## chronic cardiac disease 
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.20},
    ),
    ## AF
    atrial_fibrillation_or_flutter=patients.with_these_clinical_events(
        atrial_fibrillation_or_flutter,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.20},
    ),
    ## COPD
    current_copd=patients.with_these_clinical_events(
        current_copd,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.15},
    ),
    ## other respiratory 
    other_respiratory_conditions=patients.with_these_clinical_events(
        other_respiratory_conditions,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.05},
    ),
    ## liver disease 
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.05},
    ),
    ## Recent Stroke
    incident_stroke=patients.with_these_clinical_events(
        incident_stroke, 
        between=["index_date", "index_date - 3 months"], 
        find_first_match_in_period="true", 
        returning="binary_flag",
        return_expectations={"incidence": 0.02},
    ),
    ## Historical Stroke
    stroke_historical=patients.with_these_clinical_events(
        stroke_updated, 
        on_or_before="index_date - 3 months", 
        returning="binary_flag",
        return_expectations={"incidence": 0.05},
    ),
    ## IBD
    inflammatory_bowel_disease=patients.with_these_clinical_events(
        inflammatory_bowel_disease,
        on_or_before="index_date",
        returning="binary_flag",
        return_expectations={"incidence": 0.02},
    ),

    # COMEDICATIONS 
    ## ARBs
    arbs=patients.with_these_medications(
        angiotensin_ii_receptor_blockers_arbs,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.15},
    ),
    ## ACE
    acei=patients.with_these_medications(
        ace_inhibitor_medications,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.10},
    ),
    ## NSAIDS
    nsaids=patients.with_these_medications(
        nsaids_oral,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.10},
    ),
    ## CCB
    ccb=patients.with_these_medications(
        calcium_channel_blockers,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.20},
    ),
    ## antiplatelets
    antiplatelets=patients.with_these_medications(
        antiplatelets,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.30},
    ),
    ## lmwh
    lmwh=patients.with_these_medications(
        low_molecular_weight_heparins_dmd,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.05},
    ),
    ## doac
    doac=patients.with_these_medications(
        direct_acting_oral_anticoagulants_doac,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.10},
    ),
    ## warfarin
    warfarin=patients.with_these_medications(
        warfarin,
        between=["index_date", "index_date - 6 months"], 
        returning="binary_flag",
        return_expectations={"incidence": 0.20},
    ),
    )
    return confounding_variables