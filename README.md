# Outcomes Insights, Inc. Draft Common Data Model

A common data model (CDM) defines a set of standard locations in which information of specific types should be stored.  As such, it describes the end result of an extract, transform, and load (ETL) process for an arbitrary source (or raw) dataset.  CDM specifications can be created with a variety of goals for the resulting data model.  The goals of this CDM are twofold:

1. To minimize vocabulary mapping and restructuring in order to improve CDM adoption and to separate the data model from the vocabulary model
1. To capture the provenance of the data in order to enhance the reproducibility of studies that use the CDM

While we are inspired by CDMs such as OMOP, we find that the OMOP model requires a substantial mapping of vocabularies and domains that is intended to allow queries to operate on data from any source.  While this is a potentially powerful design goal, it results in a very complicated ETL process that varies across ETL practitioners.  It creates a steep learning curve for understanding and using novel vocabularies required to navigate the data.  And it ignores a substantial literature that uses validated algorithms based on the vocabularies in the source data, reducing transparency and reproducibility.

Therefore, as part of the data model, we do not want to incorporate information about whether a particular code represents a condition, measurement, observation, or drug exposure.  Instead, we prefer to retain data using their native vocabularies (e.g., ICD-9, HCPCS, CPT, etc.) so that we can focus on when, and in what context, the ideas represented by the codes were reported.  Hence, the fundamental premise of our CDM is that moving the data into a CDM should be separated from mapping the data to clinical research variables.

The rationale for separating these functions is that vocabulary mappings are prone to refinement and they can obscure the connection back to the source data ("provenance").  Also, mappings are not universally available (e.g., procedure vocabularies).  Furthermore, to the extent that there are potential efficiencies to expressing queries in a common vocabulary (e.g., SNOMED), this does not require that every code in the data be remapped **during the ETL process**.  Generalized queries only require a mapping from the common vocabulary (e.g., SNOMED) to the codes available in the dataset at hand, which can readily be done "on the fly."

Perhaps the simplest way to explain the philosophy of our CDM is that, if an algorithm involves a specific code, we should know the CDM table in which to look for that code regardless of the structure of the original (raw) data.  Then we should be able to leverage our library of existing algorithms and vocabulary tools to operate on the data and create all of the variables for our study datasets.  The ultimate goal is **not to have to do any ETL at all**, and to operate against the raw data directly.  However, for the time being, we are focused on building a simple CDM that involves minimal ETL, coupled with a framework for creating, storing, sharing, and using algorithms that operate on a CDM.

To this end, we have developed an open-source language, [ConceptQL](https://github.com/outcomesinsights/conceptql), that enables us to create, store, share, and use algorithms that are designed to work on electronic health information.  Our project, [Jigsaw](http://www.jigsawanalytics.com) leverages ConceptQL to create a mechanism for leveraging algorithms and vocabularies separately from the CDM.

## people

- Demographic information about the patients in the data.
- Provider_id is for HMO and similar situations (CPRD) where there is a defined primary care provider

| column               | type   | description                                                                                                                     |
| -----------------    | ----   | -----------                                                                                                                     |
| id                   | serial | A unique identifier for each person.                                                                                            |
| gender_concept_id    | int    | A foreign key that refers to an identifier in the CONCEPT table for the unique gender of the person.                            |
| birth_date           | date   | Date of birth                                                                                                                   |
| race_concept_id      | int    | A foreign key that refers to an identifier in the CONCEPT table for the unique race of the person.                              |
| ethnicity_concept_id | int    | A foreign key that refers to the standard concept identifier in the Standardized Vocabularies for the ethnicity of the person.  |
| address_id           | int    | A foreign key to the place of residency for the person in the location table, where the detailed address information is stored. |
| provider_id          | int    | A foreign key to the primary care provider the person is seeing in the provider table.                                          |

## providers

- See OMOP provider table.  Adapt to allow multiple providers via visit table

| column                      | type   | description                                                                        |
| -----------------           | ----   | -----------                                                                        |
| id                          | serial | A unique identifier for each Provider.                                             |
| provider_name               | text   | A description of the Provider.                                                     |
| identifier                  | text   | Provider identifier                                                                |
| identifier_type             | text   | Type of identifier specified in identifier field  (UPIN,NPI,etc)                   |
| dea                         | text   | The Drug Enforcement Administration (DEA) number of the provider.                  |
| specialty_concept_id        | int    | A foreign key to a Standard Specialty Concept ID in the Standardized Vocabularies. |
| address_id                  | int    | A foreign key to the address of the location where the provider is practicing.     |
| birth_date                  | int    | The date of birth of the Provider.                                                 |
| gender_concept_id           | int    | The gender of the Provider.                                                        |
| specialty_source_concept_id | int    | A foreign key to a Concept that refers to the code used in the source.             |
| gender_source_concept_id    | int    | A foreign key to a Concept that refers to the code used in the source.             |


## facilities

- Unique records for all the facilities in the data

| column                      | type   | description                                                                        |
| -----------------           | ----   | -----------                                                                        |
| id                          | serial | A unique identifier for each Provider.                                             |
| facility_name               | text   | A description of the Provider.                                                     |
| identifier                  | text   | Provider identifier                                                                |
| identifier_type             | text   | Type of identifier specified in identifier field  (UPIN,NPI,etc)                   |
| specialty_concept_id        | int    | A foreign key to a Standard Specialty Concept ID in the Standardized Vocabularies. |
| address_id                  | int    | A foreign key to the address of the location where the provider is practicing.     |

## claims

- Records the claim level information
- Includes the place of service where a claim was submitted
- Can be pointed to by multiple clinical and detail records
- Describes the claim level visit information
- Vocabularies
  - Place of service

| column                        | type   | description                                                                                 |
| -----------------             | ----   | -----------                                                                                 |
| id                            | serial | Surrogate key for record                                                                    |
| person_id                     | int    | FK to reference to person table                                                             |
| pos_concept_id                | int    | FK reference to concept table representing the place of service associated with this record |
| start_date                    | date   | Date of when record began                                                                   |
| end_date                      | date   | Date of when record ended                                                                   |
| facility_id                   | int    | FK reference to facilities table                                                            |
| file_type                     | text   | Type of the file from which the record was pulled                                           |

## claims_providers

- Links one or more providers with a claim
- Represents an encounter between a person and a provider on a specific claim
- Patients can have multiple encounters within a claim (but not the other way around)
- claims_providers captures the role, if any, the provider played on the claim (e.g., attending physician)

| column            | type   | description                                                                  |
| ----------------- | ----   | -----------                                                                  |
| claim_id          | int    | FK reference to claims table                                                 |
| provider_id       | int    | FK reference to providers table                                              |
| role_type_id      | int    | FK reference to concepts related to roles providers can play in an encounter |

## lines

- Links one or more lines to a claim
- Searching clinical_codes by line_id will return all lines that happened within a claim. This allows linkages between line diagnoses with line procedures

| column            | type   | description                                                                  |
| ----------------- | ----   | -----------                                                                  |
| id                | serial | Surrogate key for record                                                     |
| claim_id          | int    | FK reference to claims table                                                 |
| pos_concept_id    | int    | FK reference to concept table representing the place of service associated with this record  |
| provider_id       | int  | FK for provider associated with this record                                           |

## clinical_codes

- Instead of having separate condition and procedure tables, we'll include all codes from the following vocabularies:
  - ICD-9 (Proc and CM)
  - ICD-10 (Proc and CM)
  - SNOMED
  - Medcode (CPRD)
  - HCPCS/CPT
- The OMOP specification for procedure and condition tables are quite similar.  Having separate tables follows with OMOP's philosophy of classifying each concept into a specific domain.  The PCORnet CDM has two condition tables (one for results of diagnostic processes and one for condition lists), and a procedure table.  Again, these are all very similar in structure.  Since domains are semantic classifications, and since all of the tables are so similar, there is no philosophical or technical reason why we can't combine conditions and procedures into the same table.  After all, all of the above-listed vocabularies include multiple domains.
- For each code we find in the source data, we will create a new row in this table.  The code from the source data will be matched against OMOP's concept table and we will save the concept_id in this table, rather than the raw code.

| column              | type   | description                                                                           |
| -----------------   | ----   | -----------                                                                           |
| id                  | serial | Surrogate key for record                                                              |
| claim_id            | int    | FK reference to claims                                                                |
| line_id             | int    | FK reference to lines                                                                 |
| person_id           | int    | ID of person associated with this record                                              |
| start_date          | date   | Date of when clinical record began                                                    |
| end_date            | date   | Date of when clinical record ended                                                    |
| clinical_concept_id | int    | FK reference into concept table representing the clinical code assigned to the record |
| quantity            | int    | Sometimes quantity is reported in claims data for procedures                          |
| position            | int    | The position for the variable assigned e.g. dx3 gets position 3                       |
| type_concept_id     | int    | Type of clinical code (e.g., diagnosis, procedure, etc.)                              |

## details

- Additional information - measurements, observations, status, and specifications
- Text-based vocabularies should be mapped to LOINC, if possible (e.g., laboratory data indexed by text names for the lab results)
- Other vocabularies should be included in their original system (e.g., SEER variables)
  - This could be implemented by making variable names a vocabulary in themselves
- May need to add variables for "normal range", or consider a separate table for additional laboratory details

| column              | type   | description                                                                                                                                                                                                                                             |
| -----------------   | ----   | -----------                                                                                                                                                                                                                                             |
| id                  | serial | Surrogate key for record                                                                                                                                                                                                                                |
| claim_id            | int    | FK reference to claims table                                                                                                                                                                                                                            |
| line_id             | int    | FK reference to lines                                                        |
| person_id           | int    | ID of person associated with this record                                                                                                                                                                                                                |
| start_date          | date   | Date of when record began                                                                                                                                                                                                                               |
| end_date            | date   | Date of when record ended                                                                                                                                                                                                                               |
| detail_concept_id   | int    | FK reference to concept table representing the topic the detail addresses                                                                                                                                                                               |
| value_as_number     | float  | The observation result stored as a number. This is applicable to observations where the result is expressed as a numeric value.                                                                                                                         |
| value_as_string     | text   | The observation result stored as a string. This is applicable to observations where the result is expressed as verbatim text.                                                                                                                           |
| value_as_concept_id | int    | A foreign key to an observation result stored as a Concept ID. This is applicable to observations where the result can be expressed as a Standard Concept from the Standardized Vocabularies (e.g., positive/negative, present/absent, low/high, etc.). |
| unit_concept_id     | int    | A foreign key to a Standard Concept ID of measurement units in the Standardized Vocabularies.                                                                                                                                                           |

## exposures

- To capture drug and device data
- Drugs and devices captured in the clinical_codes table should remain in the clinical_codes table.
- Could include devices if they are reported separately from procedures.  Note that these may be text entries and may have mis-spellings (e.g., MedAssets and other text-based data sources).  Mapping to a vocabulary may or may not be possible.
- Vocabularies
  - NDC
  - RxNorm
  - Prodcodes (CPRD)

| column               | type   | description                                                                                                                            |
| -----------------    | ----   | -----------                                                                                                                            |
| id                   | serial | Surrogate key for record |
| claim_id            | int    | FK reference to claims table|
| line_id             | int    | FK reference to lines                                                        |
| person_id            | int    | ID of person associated with this record                                                                                               |
| start_date           | date   | Date of when record began                                                                                                              |
| end_date             | date   | Date of when record ended                                                                                                              |
| provider_id          | int    | FK reference to provider table                                                                                                         |
| exposure_concept_id  | int    | FK reference to concept table representing the exposure represented by this record                                                     |
| refills              | int    | The number of refills after the initial prescription. The initial prescription is not counted, values start with 0.                    |
| quantity             | float  | The quantity of drug as recorded in the original prescription or dispensing record.                                                    |
| days_supply          | int    | The number of days of supply of the medication as recorded in the original prescription or dispensing record.                          |
| dose_form_concept_id | int    | A foreign key to a predefined concept in the Standardized Vocabularies reflecting the form of the drug (capsule, injection,etc.)       |
| dose_unit_concept_id | int    | A foreign key to a predefined concept in the Standardized Vocabularies reflecting the unit the effective_drug_dose value is expressed. |

## costs

- To capture costs (charges, reimbursed amounts, and/or costs) for each provided service
- OI cost table

| column                        | type   | description                                                                                                                                                                       |
| -----------------             | ----   | -----------                                                                                                                                                                       |
| id                            | serial | A unique identifier for each COST record.                                                                                                                                         |
| cost_event_id                 | int    | A foreign key identifier to the event (e.g. Measurement, Procedure, Visit, Drug Exposure, etc) record for which cost data are recorded.                                           |
| table_name                    | text   | The name of the table where the associated event record is found.                                                                                                                 |
| currency_concept_id           | int    | A concept representing the 3-letter code used to delineate international currencies, such as USD for US Dollar.                                                                   |
| charge                        | float  | The amount charged by the provider of the good/service (e.g. hospital, physician pharmacy, dme provider)                                                                          |
| paid_copay                    | float  | The amount paid by the Person as a fixed contribution to the expenses. Copay does not contribute to the out of pocket expenses.                                                   |
| paid_coinsurance              | float  | The amount paid by the Person as a joint assumption of risk. Typically, this is a percentage of the expenses defined by the Payer Plan after the Person's deductible is exceeded. |
| paid_toward_deductible        | float  | The amount paid by the Person that is counted toward the deductible defined by the Payer Plan.                                                                                    |
| paid_by_payer                 | float  | The amount paid by the Payer. If there is more than one Payer, several COST records indicate that fact.                                                                           |
| paid_by_coordination_benefits | float  | The amount paid by a secondary Payer through the coordination of benefits.                                                                                                        |
| total_out_of_pocket           | float  | The total amount paid by the Person as a share of the expenses.                                                                                                                   |
| total_paid                    | float  | The total amount paid. This field should not contain an imputed value. Only populate this field if the raw data provides a clear source of information on how much was paid, in total, for this service/exposure. |
| ingredient_cost               | float  | The portion of the drug expenses due to the cost charged by the manufacturer for the drug, typically a percentage of the Average Wholesale Price.                                 |
| dispensing_fee                | float  | The portion of the drug expenses due to the dispensing fee charged by the pharmacy, typically a fixed amount.                                                                     |
| cost                          | float  | Cost of service/device/drug incurred by provider/pharmacy.  Was "average_wholesale_price" which represented: "List price of a Drug set by the manufacturer."                      |
| amount_allowed                | float  | The contracted amount the provider has agreed to accept as payment in full.                                                                                                       |
| revenue_code_concept_id       | int    | A foreign key referring to a Standard Concept ID in the Standardized Vocabularies for Revenue codes.                                                                              |

## addresses

- See OMOP location table - used for persons and care sites

| column            | type   | description                                                                                                                    |
| ----------------- | ----   | -----------                                                                                                                    |
| id                | serial | A unique identifier for each geographic location.                                                                              |
| address_1         | text   | The address field 1, typically used for the street address, as it appears in the source data.                                  |
| address_2         | text   | The address field 2, typically used for additional detail such as buildings, suites, floors, as it appears in the source data. |
| city              | text   | The city field as it appears in the source data.                                                                               |
| state             | text   | The state field as it appears in the source data.                                                                              |
| zip               | text   | The zip or postal code.                                                                                                        |
| county            | text   | The county.                                                                                                                    |

## deaths

- Capture mortality information - date and cause(s) of death
- Might want to check diagnosis codes and discharge location as part of ETL.

| column                | type   | description                                                                                           |
| -----------------     | ----   | -----------                                                                                           |
| id                    | serial | Surrogate key for record                                                                              |
| person_id             | int    | ID of person associated with this record                                                              |
| date                  | date   | Date of death                                                                                         |
| visit_id              | int    | FK reference to visit table                                                                           |
| cause_concept_id      | int    | FK reference into concept that represents cause of death                                              |
| cause_type_concept_id | int    | FK reference into concept that represents the type of cause of death (e.g. primary, secondary, etc. ) |
| provider_id           | int    | FK for provider associated with this record                                                           |

## information_periods

- Captures periods for which information in each table is relevant.
- Could include enrollment types (e.g., Part A, Part B, HMO) or just "observable" (as with up-to-standard data in CPRD)
- One row per person per enrollment type per table

| column            | type   | description                                                                                                                               |
| ----------------- | ----   | -----------                                                                                                                               |
| id                | serial | Surrogate key for record                                                                                                                  |
| person_id         | int    | ID of person associated with this record                                                                                                  |
| start_date        | date   | Date of when record began                                                                                                                 |
| end_date          | date   | Date of when record ended                                                                                                                 |
| information_type  | text   | String representing the type of data availability (e.g., insurance coverage, hospital data, up-to-standard date).  Could be concept type. |
