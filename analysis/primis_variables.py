from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta

# note these variables are named in order to agree with the NHS shielding SQL code, and therefore standardardised (if less informative) names hav ebeen retained

def generate_primis_variables(index_date):
    primis_variables = dict(
    ### Asthma diagnosis 
    ast_dat=patients.with_these_clinical_events(
        ast,
        returning="date",
        find_first_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Asthma Amission 
    astadm_dat=patients.with_these_clinical_events(
        astadm,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Asthma systemic steroid prescription code in month 1
    astrxm1_dat=patients.with_these_medications(
        astrx,
        returning="date",
        find_last_match_in_period=True,
        on_or_after="index_date - 30 days",
        date_format="YYYY-MM-DD",
    ),
    ### Asthma systemic steroid prescription code in month 2
    astrxm2_dat=patients.with_these_medications(
        astrx,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date - 31 days",
        on_or_after="index_date - 60 days",
        date_format="YYYY-MM-DD",
    ),
    ### Asthma systemic steroid prescription code in month 3
    astrxm3_dat=patients.with_these_medications(
        astrx,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date - 61 days",
        on_or_after="index_date - 90 days",
        date_format="YYYY-MM-DD",
    ),
    ### Chronic Respiratory Disease
    resp_cov_dat=patients.with_these_clinical_events(
        resp_cov,
        returning="date",
        find_first_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Chronic heart disease codes
    chd_cov_dat=patients.with_these_clinical_events(
        chd_cov,
        returning="date",
        find_first_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ###  Chronic kidney disease diagnostic codes
    ckd_cov_dat=patients.with_these_clinical_events(
        ckd_cov,
        returning="date",
        find_first_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Chronic kidney disease codes - all stages
    ckd15_dat=patients.with_these_clinical_events(
        ckd15,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Chronic kidney disease codes-stages 3 - 5
    ckd35_dat=patients.with_these_clinical_events(
        ckd35,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Chronic Liver disease codes
    cld_dat=patients.with_these_clinical_events(
        cld,
        returning="date",
        find_first_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Diabetes diagnosis codes
    diab_dat=patients.with_these_clinical_events(
        diab,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Immunosuppression diagnosis codes
    immdx_cov_dat=patients.with_these_clinical_events(
        immdx_cov,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Immunosuppression medication codes
    immrx_dat=patients.with_these_medications(
        immrx,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        on_or_after="2020-01-01",
        date_format="YYYY-MM-DD",
    ),
    ### Chronic Neurological Disease including Significant Learning Disorder
    cns_cov_dat=patients.with_these_clinical_events(
        cns_cov,
        returning="date",
        find_first_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Asplenia or Dysfunction of the Spleen codes
    spln_cov_dat=patients.with_these_clinical_events(
        spln_cov,
        returning="date",
        find_first_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### BMI
    bmi_dat=patients.with_these_clinical_events(
        bmi,
        returning="date",
        ignore_missing_values=True,
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    bmi_val=patients.with_these_clinical_events(
        bmi,
        returning="numeric_value",
        ignore_missing_values=True,
        find_last_match_in_period=True,
        on_or_before="index_date",
        return_expectations={
            "float": {"distribution": "normal", "mean": 25, "stddev": 5},
        },
    ),
    ### All BMI coded terms
    bmi_stage_dat=patients.with_these_clinical_events(
        bmi_stage,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Severe Obesity code recorded
    sev_obesity_dat=patients.with_these_clinical_events(
        sev_obesity,
        returning="date",
        ignore_missing_values=True,
        find_last_match_in_period=True,
        on_or_after="bmi_stage_dat",
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Diabetes resolved codes
    dmres_dat=patients.with_these_clinical_events(
        dmres,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Severe Mental Illness codes
    sev_mental_dat=patients.with_these_clinical_events(
        sev_mental,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Remission codes relating to Severe Mental Illness
    smhres_dat=patients.with_these_clinical_events(
        smhres,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    ### Wider Learning Disability (added later, so only included as a variable - will not be used to define population)
    learndis_dat=patients.with_these_clinical_events(
        learndis,
        returning="date",
        find_last_match_in_period=True,
        on_or_before="index_date",
        date_format="YYYY-MM-DD",
    ),
    )
    return primis_variables