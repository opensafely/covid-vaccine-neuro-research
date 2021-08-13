from cohortextractor import (
    codelist,
    codelist_from_csv,
)
# OUTCOMES
bells_palsy_primary_care_codes = codelist_from_csv(
    "codelists/opensafely-bells-palsy.csv",
    system="ctv3",
    column="code",
)
bells_palsy_secondary_care_codes = codelist_from_csv(
    "codelists/opensafely-bells-palsy-icd-10.csv",
    system="icd10",
    column="code",
)
bells_palsy_emergency_care_codes = codelist(["193093009"], system="snomed")
transverse_myelitis_primary_care_codes = codelist_from_csv(
    "codelists/opensafely-transverse-myelitis.csv",
    system="ctv3",
    column="CTV3Code",
)
transverse_myelitis_secondary_care_codes = codelist_from_csv(
    "codelists/opensafely-acute-transverse-myelitis-icd-10.csv",
    system="icd10",
    column="code",
)
guillain_barre_primary_care_codes = codelist_from_csv(
    "codelists/opensafely-guillain-barre.csv",
    system="ctv3",
    column="code",
)
guillain_barre_secondary_care_codes = codelist_from_csv(
    "codelists/opensafely-guillain-barre-syndrome-icd10.csv",
    system="icd10",
    column="code",
)
# COVARIATES
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
diabetes = codelist_from_csv(
    "codelists/opensafely-diabetes.csv",
    system="ctv3",
    column="CTV3ID",
)
hiv = codelist_from_csv(
    "codelists/opensafely-hiv.csv",
    system="ctv3",
    column="CTV3ID",
)
cancer_excluding_lung_and_haematological = codelist_from_csv(
    "codelists/opensafely-cancer-excluding-lung-and-haematological.csv",
    system="ctv3",
    column="CTV3ID",
)
lung_cancer = codelist_from_csv(
    "codelists/opensafely-lung-cancer.csv",
    system="ctv3",
    column="CTV3ID",
)
haematological_cancer = codelist_from_csv(
    "codelists/opensafely-haematological-cancer.csv",
    system="ctv3",
    column="CTV3ID",
)
systemic_lupus = codelist_from_csv(
    "codelists/opensafely-systemic-lupus-erythematosus-sle.csv",
    system="ctv3",
    column="CTV3ID",
)
hypertension = codelist_from_csv(
    "codelists/opensafely-hypertension.csv",
    system="ctv3",
    column="CTV3ID",
)
preg = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-preg.csv",
    system="snomed",
    column="code",
)
ms_primary_care = codelist_from_csv(
    "codelists/opensafely-multiple-sclerosis.csv",
    system="ctv3",
    column="CTV3ID",
)
ms_secondary_care = codelist_from_csv(
    "codelists/user-anna-schultze-multiple-sclerosis-icd10.csv",
    system="icd10",
    column="code",
)
adem_primary_care = codelist_from_csv(
    "codelists/user-anna-schultze-acute-disseminated-encephalitis-and-encephalomyelitis.csv",
    system="ctv3",
    column="code",
)
adem_secondary_care = codelist_from_csv(
    "codelists/user-anna-schultze-acute-disseminated-encephalitis-and-encephalomyelitis-icd10.csv",
    system="icd10",
    column="code",
)
neuromyelitis_optica_primary_care = codelist_from_csv(
    "codelists/user-anna-schultze-neuromyelitis-optica.csv",
    system="ctv3",
    column="code",
)
neuromyelitis_optica_secondary_care = codelist_from_csv(
    "codelists/user-anna-schultze-neuromyelitis-optica-icd-10.csv",
    system="icd10",
    column="code",
)
cidp_primary_care = codelist_from_csv(
    "codelists/user-anna-schultze-chronic-inflammatory-demyelinating-polyneuritis.csv",
    system="ctv3",
    column="code",
)

