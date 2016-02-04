# Outcomes Insights, Inc. Draft Data Model

For the purposes of organizing data, we define a data model as a set of standard locations in which information of specific types should be stored, as well as how they relate to one another.  As such, it describes the end result of an extract, transform, and load (ETL) process for an arbitrary source (or raw) dataset.  Data models can be created with a variety of goals; the goals of our data model are four-fold:

1. To simplify table structures making them easier to understand, easier to create in the ETL process, and faster to query
1. To minimize any required vocabulary mapping
1. To capture the provenance of the data in order to enhance the reproducibility of studies that use the data model
1. To enable a straightforward, subsequent ETL process to other data models, including OMOP and PCORnet

The focus of our data model is on the source vocabulary (i.e., the vocabulary of the original data).  This approach will allow us to utilize the substantial literature of validated algorithms based on the the source data vocabularies, enhancing transparency and reproducibility.  Therefore, as part of the data model itself, we do not separate clinical events into conditions, procedures, measurements, observations, or drug exposures.  They are all simply clinical events, with codes to identify them.  Hence, we store data using their native vocabularies (e.g., ICD-9, HCPCS, CPT, etc.) so that we can focus on when, and in what context, the ideas represented by the codes were reported.  

The rationale for separating the vocabulary mapping process from the data model is that vocabulary mappings are prone to continuous refinement, and they are not available for all vocabularies (e.g., procedure vocabularies).  Furthermore, to the extent that there are potential efficiencies to expressing queries in a common vocabulary (e.g., SNOMED), this does not require that every code in the data be remapped **during the ETL process**.  Queries that work across datasets with different source vocabularies can readily be done "on the fly."  The excellent vocabulary mappings provided by the Observational Health Data Science and Informatics (OHDSI) community make such a process easy to implement. 

Perhaps the simplest way to explain the philosophy of our data model is that, if an algorithm involves a specific code, we should know the data model table in which to look for that code regardless of the structure of the original (raw) data.  Then we should be able to leverage a library of existing algorithms and vocabulary tools to operate on the data and create all of the variables for our study datasets.  To this end, we have developed an open-source language, [ConceptQL](https://github.com/outcomesinsights/conceptql_spec), that enables us to create, store, share, and use algorithms that are designed to work on electronic health information.  Our project, [Jigsaw](http://www.jigsaw.io) leverages ConceptQL to apply algorithms and vocabularies against data in our data model to build study datasets.  (And Jigsaw is designed so that the algorithms work, not only across datasets, but also across data **models**.)

Below is the current version of the schema for the OI Data Model.  We gratefully acknowledge the influence of the open-source OHDSI common data model [specifications](http://www.ohdsi.org/web/wiki/doku.php?id=documentation:cdm) on our thinking in creating this data model.  At the moment, all references to the concepts table refer to the OMOP version 5 vocabulary concepts [table](http://www.ohdsi.org/web/athena/).

## people

- Demographic information about the patients in the data
- The column for *provider_id* is intended for situations where there is a defined primary care provider (e.g., HMO or CPRD data)

| column               | type   | description                                                                                                                     |
| -----------------    | ----   | -----------                                                                                                                     |
| id                   | serial | A unique identifier for each person                                                                                            |
| gender_concept_id    | int    | A foreign key that refers to an identifier in the concepts table for the unique gender of the person                            |
| birth_date           | date   | Date of birth (yyyy-mm-dd)                                                                                                     |
| race_concept_id      | int    | A foreign key that refers to an identifier in the concepts table for the unique race of the person                              |
| ethnicity_concept_id | int    | A foreign key that refers to an identifier in the concepts table for the ethnicity of the person                               |
| address_id           | int    | A foreign key to the place of residency for the person in the location table, where the detailed address information is stored |
| provider_id          | int    | A foreign key to the primary care provider the person is seeing in the provider table                                          |

## providers

- All non-facility providers (i.e., physicians, etc.) are listed

| column                      | type   | description                                                                        |
| -----------------           | ----   | -----------                                                                        |
| id                          | serial | A unique identifier for each provider                                             |
| provider_name               | text   | Provider name, if available                                                     |
| identifier                  | text   | Provider identifier                                                                |
| identifier_type             | text   | Type of identifier specified in identifier field  (UPIN, NPI, etc)                   |
| dea                         | text   | The Drug Enforcement Administration (DEA) number of the provider                  |
| specialty_concept_id        | int    | A foreign key to an identifier in the concepts table for specialty     |
| address_id                  | int    | A foreign key to the address of the location where the provider is practicing     |
| birth_date                  | int    | Date of birth (yyyy-mm-dd)                                                |
| gender_concept_id           | int    | A foreign key that refers to an identifier in the concepts table for the unique gender of the person               |


## facilities

- Unique records for all the facilities in the data

| column                      | type   | description                                                                        |
| -----------------           | ----   | -----------                                                                        |
| id                          | serial | A unique identifier for each facility                                             |
| facility_name               | text   | Facility name, if available                                                     |
| identifier                  | text   | Facility identifier                                                                |
| identifier_type             | text   | Type of identifier specified in identifier field  (UPIN,NPI,etc)                   |
| specialty_concept_id        | int    | A foreign key to an identifier in the concepts table for specialty |
| address_id                  | int    | A foreign key to the address of the location of the facility     |

## claims

- Records the claim level information (also referred to as "headers" in some databases)
- Often claims refer to groups of records from the lines table
- Includes the place of service recorded with the record
- Can be linked with multiple records in the clinical_codes, details, and exposures tables

| column                        | type   | description                                                                                 |
| -----------------             | ----   | -----------                                                                                 |
| id                            | serial | Surrogate key for record                                                                    |
| person_id                     | int    | FK to reference to person table                                                             |
| pos_concept_id                | int    | FK reference to concepts table representing the place of service associated with this record |
| start_date                    | date   | Start date of record (yyyy-mm-dd)                                                                  |
| end_date                      | date   | End date of record (yyyy-mm-dd)                                                                  |
| facility_id                   | int    | FK reference to facilities table                                                            |
| file_type                     | text   | Type of the file from which the record was pulled (currently a text field; for provenance purposes)      |

## claims_providers

- Links one or more providers with a claim
- Each record represents an encounter between a person and a provider on a specific claim
- Captures the role, if any, the provider played on the claim (e.g., attending physician)

| column            | type   | description                                                                  |
| ----------------- | ----   | -----------                                                                  |
| claim_id          | int    | FK reference to claims table                                                 |
| provider_id       | int    | FK reference to providers table                                              |
| role_type_id      | text   | Roles providers can play in an encounter (currently a text field)         |

## lines

- A line is a set of directly connected pieces of information (e.g., a diagnosis and a procedure), typically occurring on the same day or at the same time
- Always linked to a single claim

| column            | type   | description                                                                  |
| ----------------- | ----   | -----------                                                                  |
| id                | serial | Surrogate key for record                                                     |
| claim_id          | int    | FK reference to claims table                                                 |
| pos_concept_id    | int    | FK reference to concepts table representing the place of service associated with this record  |
| provider_id       | int    | FK for provider associated with this record                                           |

## clinical_codes

- Stores clinical codes from all types of records including procedures and diagnoses.
  - ICD-9 (Proc and CM)
  - ICD-10 (Proc and CM)
  - SNOMED
  - Medcode (CPRD)
  - HCPCS/CPT
- Ignores semantic distinctions about the type of information represented within a vocabulary because most vocabularies contain information from more than one domain
- One record generated for each individual code in the raw data
- Consider using this as fact table in dimensional schema (if used)
- Consider moving common fields from the exposures and details tables to this table, and using those tables to store only additional information specific to those domains

| column              | type   | description                                                                           |
| -----------------   | ----   | -----------                                                                           |
| id                  | serial | Surrogate key for record                                                              |
| claim_id            | int    | FK reference to claims table                                                             |
| line_id             | int    | FK reference to lines table                                                              |
| person_id           | int    | FK reference to people table                                            |
| start_date          | date   | Start date of record (yyyy-mm-dd)                                                    |
| end_date            | date   | End date of record (yyyy-mm-dd)                                                    |
| clinical_concept_id | int    | FK reference to concepts table for the code assigned to the record   |
| quantity            | int    | Quantity, if available (e.g., procedures)                           |
| position            | int    | The position for the variable assigned (e.g. dx3 gets position 3)                       |
| type_concept_id     | int    | Additional type information.  Do we need this?                                  |

## details

- Additional information - measurements, observations, status, and specifications
- Text-based vocabularies should be mapped to LOINC, if possible (e.g., laboratory data indexed by text names for the lab results)
- Other vocabularies should be included in their original system (e.g., SEER variables)
  - This could be implemented by making variable names a vocabulary in themselves
- May need to add variables for "normal range", or consider a separate table for additional laboratory details

| column              | type   | description                                                                                                                                                                                                                                             |
| -----------------   | ----   | -----------                                                                                                                                                                                                                                             |
| id                  | serial | Surrogate key for record                                                                                                                                                                                                                                |
| claim_id            | int    | FK reference to claims table                                                    |
| line_id             | int    | FK reference to lines table                                             |
| person_id           | int    | FK reference to people table                                                        |
| start_date          | date   | Start date of record (yyyy-mm-dd)                                     |
| end_date            | date   | End date of record (yyyy-mm-dd) |
| detail_concept_id   | int    | FK reference to concepts table for the code assigned to the record     |
| value_as_number     | float  | The observation result stored as a number, applicable to observations where the result is expressed as a numeric value    |
| value_as_string     | text   | The observation result stored as a string, applicable to observations where the result is expressed as verbatim text    |
| value_as_concept_id | int    | FK reference to concepts table for the result associated with the detail_concept_id (e.g., positive/negative, present/absent, low/high, etc.) |
| unit_concept_id     | int    | FK reference to concepts table for the measurement units (e.g., mmol/L, mg/dL, etc.)        |

## exposures

- To capture drug and device data
- Drugs and device records recorded in the clinical_codes table should remain in the clinical_codes table (e.g., HCPCS drug codes)
- Could include devices if they are reported separately from their associated procedures.  Note that these may be text entries and may have mis-spellings.  Mapping to a vocabulary may or may not be possible.
- Example vocabularies
  - NDC
  - RxNorm
  - Prodcodes (CPRD)

| column               | type   | description                                                                                                                            |
| -----------------    | ----   | -----------                                                                                                                            |
| id                   | serial | Surrogate key for record |
| claim_id             | int     | FK reference to claims table|
| line_id              | int     | FK reference to lines table                                                        |
| person_id            | int    | FK reference to people table                                                                                            |
| start_date           | date   | Start date of record (yyyy-mm-dd)                                                                                                             |
| end_date             | date   | End date of record (yyyy-mm-dd)                                                                                                              |
| provider_id          | int    | FK reference to providers table                                                                                                         |
| exposure_concept_id  | int    | FK reference to concepts table for the code assigned to the record                                                     |
| refills              | int    | The number of refills after the initial prescription; the initial prescription is not counted (i.e., values start with 0)              |
| quantity             | float  | The quantity of drug as recorded in the original prescription or dispensing record (e.g.,, number of pills, vials, etc.)                      |
| days_supply          | int    | The number of days of supply as recorded in the original prescription or dispensing record                          |
| dose_form_concept_id | int    | FK reference to concepts table for the form of the drug (capsule, injection, etc.)       |
| dose_unit_concept_id | int    | FK reference to concepts table for the units in which the dose_value is expressed |
| dose_value           | float  | Numeric value for the dose of the drug |

## costs

- To capture costs (charges, paid amounts, and/or costs) for each provided service
- All costs are linked to a claim and could also be linked to a line, to align with the original data
- Do we need a column to indicate payer if there is more than 1 row associated with a cost record?
- Should revenue codes be in clinical_codes table?  Same with DRG and APC codes?

| column                        | type   | description                                                                                                                                                                       |
| -----------------             | ----   | -----------                                                                                                                                                                       |
| id                            | serial | A unique identifier for each COST record                                                                                                                                         |
| claim_id                      | int    | FK reference to claims table                                                    |
| line_id                       | int    | FK reference to lines table                                             |
| currency_concept_id           | int    | FK reference to concepts table for the 3-letter code used to delineate international currencies (e.g., USD = US Dollar)                                                                   |
| total_charge                  | float  | The amount charged by the provider of the good/service (e.g. hospital, physician pharmacy, dme provider)                                                                          |
| paid_copay                    | float  | The amount paid by the person as a fixed contribution to the expenses. Copay does not contribute to the out of pocket expenses.                                                   |
| paid_coinsurance              | float  | The amount paid by the person as a joint assumption of risk. Typically, this is a percentage of the expenses defined by the payer after the person's deductible is exceeded |
| paid_toward_deductible        | float  | The amount paid by the person that is counted toward the deductible defined by the Payer Plan.                                                                                    |
| paid_by_payer                 | float  | The amount paid by the payer. If there is more than one payer, several COST records indicate that fact.  This would be the sum of ingredient cost and dispensing fee for pharmacy records that include both values|
| paid_by_coordination_benefits | float  | The amount paid by a secondary Payer through the coordination of benefits                                                                                                        |
| total_out_of_pocket           | float  | The total amount paid by the Person as a share of the expenses                                                                                                                   |
| total_paid                    | float  | The total amount paid. This field should not contain an imputed value. Only populate this field if the raw data provides a clear source of information on how much was paid, in total, for this service/exposure |
| total_cost                    | float  | Cost of service/device/drug incurred.  Often calculated from charges using cost to charge ratios.  Corresponds with total_paid and total_charge amounts if all are available      |
| amount_allowed                | float  | The contracted amount the provider has agreed to accept as payment in full                                                                                                       |
| revenue_code_concept_id       | int    | FK reference to the revenue code assigned to the record                                                       |

## addresses

- Used for persons, providers, and facilities

| column            | type   | description                                                                                                                    |
| ----------------- | ----   | -----------                                                                                                                    |
| id                | serial | A unique identifier for each geographic location                                                                              |
| address_1         | text   | Typically used for street address                                  |
| address_2         | text   | Typically used for additional detail such as building, suite, floor, etc. |
| city              | text   | The city field as it appears in the source data (should this be standardized?)                                                                               |
| state             | text   | The state field as it appears in the source data (should this be standardized to 2-letter states?)                                                                             |
| zip               | text   | The zip or postal code                                                                                                        |
| county            | text   | The county (should this be standardized to county code?)                                                                                                                    |

## deaths

- Capture mortality information including date and cause(s) of death
- Commonly populated from beneficiary or similar administrative data associated with the medical record
- Might need to check discharge status as part of ETL process to fill this out completely
- Use of *claim_id* and *line_id* is not necessary since deaths are in the clinical_codes table if they are specific diagnosis codes from an encounter
- Should this just be in the clinical_codes table?

| column                | type   | description                                                                                           |
| -----------------     | ----   | -----------                                                                                           |
| id                    | serial | Surrogate key for record 
| person_id             | int    | FK reference to people table                                                              |
| date                  | date   | Date of death (yyyy-mm-dd)                                                                                        |
| cause_concept_id      | int    | FK reference to concepts table for cause of death (typically ICD-9 or ICD-10 code)                                              |
| cause_type_concept_id | int    | FK reference to concepts table for the type of cause of death (e.g. primary, secondary, etc. ) |
| provider_id           | int    | FK reference to providers table                                                           |

## information_periods

- Captures periods for which information in each table is relevant
- Could include enrollment types (e.g., Part A, Part B, HMO) or just "observable" (as with up-to-standard data in CPRD)
- One row per person per enrollment type per table

| column            | type   | description                                                                                                                               |
| ----------------- | ----   | -----------                                                                                                                               |
| id                | serial | Surrogate key for record                                                                                                                  |
| person_id         | int    | FK reference to people table                                                                                                  |
| start_date        | date   | Start date of record (yyyy-mm-dd)                                                                                                                 |
| end_date          | date   | End date of record (yyyy-mm-dd)                                                                                                                 |
| information_type  | text   | String representing the type of data availability (e.g., insurance coverage, hospital data, up-to-standard date).  Could be concept type. |

## admission_details

- Captures details about admissions and emergency department encounters that don't go in the clinical_codes, lines, or claims tables
- One row per admission
- Should handle this in the same way as "extra" information from exposures table and details table if some of their information is moved into clinical_codes
- Should we add "stay_type" to capture "observation stays" that are in the hospital but counted as outpatient facility visits?

| column            | type   | description                                                                                                                               |
| ----------------- | ----   | -----------                                                                                                                               |
| id                | serial | Surrogate key for record                                                                                                                  |
| person_id         | int    | FK reference to people table                                                                                                  |
| claim_id          | int    | FK reference to claims table                                                                                                                |
| admit_source      | text   | Database specific code indicating source of admission (e.g., ER visit, transfer, etc.)                                                               |
| discharge_location| text   | Database specific code indicating source of discharge (e.g., death, home, transfer, long-term care, etc.)                             |

## concepts

- Adapted from OMOP concept table (could add other fields, like domain, if needed)

| column            | type   | description                                                                                                                               |
| ----------------- | ----   | -----------                                                                                                                               |
| id                | serial | Surrogate key for record (this is the concept_id)                                                                                                                 |
| vocabulary_id     | text   | Unique text-string identifier of the vocabulary (see OMOP or UMLS)                                                                                           |
| concept_code      | text   | Actual code as text string from the source vocabulary (e.g., "410.00" for ICD-9)                                                                                                                |
| concept_text      | text   | Text descriptor associated with the concept_code                                                              |
| discharge_location| text   | Database specific code indicating source of discharge (e.g., death, home, transfer, long-term care, etc.)                             |

