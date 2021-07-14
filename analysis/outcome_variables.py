from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


def generate_outcome_variables(index_date):
    outcome_variables = dict(

    ## any
    any_vte_gp=patients.with_these_clinical_events(
        vte_codes_primary_care,
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    any_vte_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=vte_codes_secondary_care,
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_vte_death=patients.with_these_codes_on_death_certificate(
       vte_codes_secondary_care,
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_vte=patients.minimum_of("any_vte_gp", "any_vte_hospital", "any_vte_death"), 

    ## dvt 
    dvt_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["dvt"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    dvt_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["dvt"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    dvt_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["dvt"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_dvt=patients.minimum_of("dvt_gp", "dvt_hospital", "dvt_death"), 
    ## pe
    pe_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["pe"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    pe_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["pe"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    pe_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["pe"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_pe=patients.minimum_of("pe_gp", "pe_hospital", "pe_death"), 
    ##cvt 
    cvt_vte_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["cvt"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    cvt_vte_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["cvt"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    cvt_vte_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["cvt"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_cvt_vte=patients.minimum_of("cvt_vte_gp", "cvt_vte_hospital", "cvt_vte_death"), 
    ## portal 
    portal_vte_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["portal"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    portal_vte_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["portal"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    portal_vte_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["portal"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_portal_vte=patients.minimum_of("portal_vte_gp", "portal_vte_hospital", "portal_vte_death"), 
    ## smv 
    smv_vte_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["smv"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    ### no ICD-10 codes for SMV in hospital/death records 

    ## hepatic 
    hepatic_vte_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["hepatic"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    hepatic_vte_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["hepatic"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    hepatic_vte_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["hepatic"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_hepatic_vte=patients.minimum_of("hepatic_vte_gp", "hepatic_vte_hospital", "hepatic_vte_death"), 
    ## vena cava 
    vc_vte_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["vc"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ), 
    vc_vte_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["vc"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    vc_vte_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["vc"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_vc_vte=patients.minimum_of("vc_vte_gp", "vc_vte_hospital", "vc_vte_death"), 
    ## unspecified 
    unspecified_vte_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["unspecified"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    unspecified_vte_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["unspecified"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    unspecified_vte_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["unspecified"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_unspecified_vte=patients.minimum_of("unspecified_vte_gp", "unspecified_vte_hospital", "unspecified_vte_death"), 
    ## renal 
    ### no GP codes for renal 
    renal_vte_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=filter_codes_by_category(vte_codes_secondary_care, include=["renal"]),
        on_or_after="index_date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    renal_vte_death=patients.with_these_codes_on_death_certificate(
       filter_codes_by_category(vte_codes_secondary_care, include=["renal"]),
       on_or_after="index_date",
       match_only_underlying_cause=False,
       returning="date_of_death", 
       date_format="YYYY-MM-DD",
       return_expectations={"date": {"earliest": "index_date"}},
    ), 
    any_renal_vte=patients.minimum_of("renal_vte_hospital", "renal_vte_death"), 
    ## other 
    other_vte_gp=patients.with_these_clinical_events(
        filter_codes_by_category(vte_codes_primary_care, include=["other"]),
        returning="date", 
        date_format="YYYY-MM-DD",
        on_or_after="index_date",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),

    ### no ICD-10 codes for other 

    )
    return outcome_variables