# Generalized Data Model

We define a data model as a set of standard tables in which specific information should be stored. It defines the end result of an extract, transform, and load (ETL) process for an arbitrary source (or raw) healthcare dataset. The goals of the generalized data model are three-fold:

1. To simplify the location of clinical codes without needing specialized mappings and tables to support different types of codes
2. To capture hierarchical relationships among data elements within a relational data structure without requiring visits to be created and used for establishing these relationships
3. To develop a sufficiently generalized data model that can be readily transformed to other data models, including OMOP and Sentinel

The focus of our data model is on the information in the source vocabulary (i.e., the vocabularies used in the original data), as stored in the [clinical_codes](#clinical_codes) table. In particular, we avoid translating codes from one vocabulary to another.  In a few very simple cases like gender and race/ethnicity, we include mappings to make it easier for users of our study-builder to filter data; however, we still retain and return the original coding for these variables. 

By storing all codes of any kind in a single, large table, we gain substantial flexibility in capturing the relationships among these data elements. This is operationalized using the "[contexts](#contexts)" and "[collections](#collections)" tables. In our model, the "context" captures both the provenance of the data as well as the types of relationships among related data elements that share a context id. These relationship types depend on the data and can be identified using the record_type_concept_id. In administrative billing data, related records are often "lines" or "details" which are records that associate procedures with specific diagnoses, procedures with procedure modifiers, or procedures with [payer_reimbursements](#payer_reimbursements). In electronic health record data, relationship types may include sequences of prescription records or laboratory measures captured at the one time. 

The [collections](#collections) table represents a higher level of hierarchy for records in the [contexts](#contexts) table. That is, [collections](#collections) are groups of [contexts](#contexts). This kind of grouping occurs when multiple billable units ("lines" or "details") are combined into invoices ("claims" or "headers"). It also occurs when prescriptions, laboratory measures, diagnoses and/or procedures are all recorded at a single office visit. In short, a "Collection" is typically a "claim" or a "visit" depending on whether the source data is administrative billing or electronic health record data. In organizing the data this way, we avoid the need to construct "visits" from claims data which often leads to inaccuracy, loss of information, and complicated ETL processing.

The strength of the generalized structure is that it allows users to query data according to its native set of relationships instead of using visits, which are not native to all data sources.  This facilitates the use of a substantial literature of validated algorithms, enhancing transparency and reproducibility.  These algorithms can be used to identify clinical conditions like "diabetes" or "breast cancer" as well as clinical encounters like "visits", "hospitalizations", or "emergency room visits". 

Virtually every algorithm begins by selecting patients with at least one of a set of relevant codes, all of which are found in the [clinical_codes](#clinical_codes) table. This allows researchers to use vocabulary tools and/or a broad library of existing algorithms to create all of the variables for study datasets. To this end, we have developed an open-source language, [ConceptQL](https://github.com/outcomesinsights/conceptql_spec), that enables researchers to create, store, share, and use algorithms that are designed to work on electronic health information. Our project, [Jigsaw](http://www.jigsaw.io) leverages ConceptQL to define and apply algorithms against data in our data model to build study datasets. (And Jigsaw is designed so that algorithms also work across supported data models as well.)

Below is the current version of the schema for the Generalized Data Model. We gratefully acknowledge the influence of the OHDSI community and the open-source OMOP common data model [specifications](http://www.ohdsi.org/web/wiki/doku.php?id=documentation:cdm) on our thinking. In addition, we acknowledge the influence of both Sentinel and i2b2 on our approach, although most of our data model was designed prior to fully reviewing other data models. At the moment, many references to the [concepts](#concepts) table refer to the OMOP version 5 vocabulary [table](http://www.ohdsi.org/web/athena/) maintained by OHDSI.  However, any internally consistent set of vocabularies with unique concept ids would be sufficient (e.g., the [National Library of Medicine Metathesaurus](https://www.nlm.nih.gov/research/umls/knowledge_sources/metathesaurus/)).

## [patients](#patients)

- Demographic information about the [patients](#patients) in the data
- The column for _practitioner_id_ is intended for situations where there is a defined primary care practitioner (e.g., HMO or CPRD data)

column                  | type   | description                                                                                                                     | foreign key                    | required |
----------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------- | -------------------------------| -------- |
id                      | serial | A unique identifier for each patient                                                                                            |                                |     x    |
gender_concept_id       | bigint | A foreign key that refers to an identifier in the [concepts](#concepts) table for the unique gender of the patient              | [concepts](#concepts)          |          |
birth_date              | date   | Date of birth (yyyy-mm-dd)                                                                                                      |                                |          |
race_concept_id         | bigint | A foreign key that refers to an identifier in the [concepts](#concepts) table for the unique race of the patient                | [concepts](#concepts)          |          |
ethnicity_concept_id    | bigint | A foreign key that refers to an identifier in the [concepts](#concepts) table for the ethnicity of the patient                  | [concepts](#concepts)          |          |
address_id              | bigint | A foreign key to the place of residency for the patient in the location table, where the detailed address information is stored | [addresses](#addresses)        |          |
practitioner_id         | bigint | A foreign key to the primary care practitioner the patient is seeing in the [practitioners](#practitioners) table               | [practitioners](#practitioners)|          |
patient_id_source_value | text   | Originial patient identifier defined in the source data                                                                         |                                |     x    |

## [patient_details](#patient_details)

- Extra information about a patient that doesn't fit in the [patients](#patients) table

column                       | type   | description                                                                     | foreign key                  | required |
---------------------------- | ------ | ------------------------------------------------------------------------------- | -----------------------------|----------|
id                           | serial | A unique identifier for each patient_detail                                     |                              |     x    |
patient_id                   | bigint | FK reference to [patients](#patients) table                                     | [patients](#patients)        |     x    |
patient_detail_concept_id    | bigint | FK reference to [concepts](#concepts) table for the code assigned to the record | [concepts](#concepts)        |     x    |
patient_detail_source_value  | text   | Source code from raw data                                                       |                              |     x    |
patient_detail_vocabulary_id | text   | Vocabulary the patient detail comes from                                        | [vocabularies](#vocabularies)|     x    |

## [practitioners](#practitioners)

- All non-facility [practitioners](#practitioners) (i.e., physicians, etc.) are listed

column                    | type   | description                                                                                                       | foreign key            | required 
------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------- | -----------------------| -------- 
id                        | serial | A unique identifier for each practitioner                                                                         |                        |     x    
practitioner_name         | text   | [practitioners](#practitioners) name, if available                                                                |                        |          
primary_identifier        | text   | Primary practitioner identifier                                                                                   |                        |         
primary_identifier_type   | text   | Type of identifier specified in primary identifier field (UPIN, NPI, etc)                                         |                        |         
secondary_identifier      | text   | Secondary practitioner identifier (Optional)                                                                      |                        |          
secondary_identifier_type | text   | Type of identifier specified in secondary identifier field (UPIN, NPI, etc)                                       |                        |          
specialty_concept_id      | bigint | A foreign key to an identifier in the [concepts](#concepts) table for specialty                                   | [concepts](#concepts)  |          
address_id                | bigint | A foreign key to the address of the location where the practitioner is practicing                                 | [addresses](#addresses)|          
birth_date                | date   | Date of birth (yyyy-mm-dd)                                                                                        |                        |         
gender_concept_id         | bigint | A foreign key that refers to an identifier in the [concepts](#concepts) table for the unique gender of the person | [concepts](#concepts)  |          

## [facilities](#facilities)

- Unique records for all the [facilities](#facilities) in the data
- facility_type_concept_id should be used to describe the whole facility (e.g., Academic Medical Center or Community Medical Center). Specific departments in the facility should be entered in the [contexts](#contexts) table using the care_site_type_concept_id field.

column                    | type   | description                                                                     | foreign key            | required 
------------------------- | ------ | ------------------------------------------------------------------------------- | -----------------------| --------
id                        | serial | A unique identifier for each facility                                           |                        |     x    
facility_name             | text   | Facility name, if available                                                     |                        |         
primary_identifier        | text   | Primary facility identifier                                                     |                        |         
primary_identifier_type   | text   | Type of identifier specified in primary identifier field (UPIN, NPI, etc)       |                        |         
secondary_identifier      | text   | Secondary facility identifier (Optional)                                        |                        |         
secondary_identifier_type | text   | Type of identifier specified in secondary identifier field (UPIN, NPI, etc)     |                        |
facility_type_concept_id  | bigint | FK reference to [concepts](#concepts) table representing the facility type      | [concepts](#concepts)  |         
specialty_concept_id      | bigint | A foreign key to an identifier in the [concepts](#concepts) table for specialty | [concepts](#concepts)  |         
address_id                | bigint | A foreign key to the address of the location of the facility                    | [addresses](#addresses)|         

## [collections](#collections)

- Used to group [contexts](#contexts) records
- For claims, records the claim level information (also referred to as "headers" in some databases)

  - Use claim from and thru date for start and end date, if available
  - Admit and discharge dates should go in the [admission_details](#admission_details) table unless those are the only dates for the records in which case they should be entered into both the [collections](#collections) and [admission_details](#admission_details) tables

- For EHR, records the visit level information

- Includes the place of service recorded with the record


column              | type   | description                                                   | foreign key                            | required 
------------------- | ------ | ------------------------------------------------------------- | ---------------------------------------| --------
id                  | serial | Surrogate key for record                                      |                                        |     x     
patient_id          | bigint | FK to reference to [patients](#patients) table                | [patients](#patients)                  |     x     
start_date          | date   | Start date of record (yyyy-mm-dd)                             |                                        |     x     
end_date            | date   | End date of record (yyyy-mm-dd)                               |                                        |         
duration            | float  | Duration of collection. (e.g. hospitalization length of stay) |                                        |          
duration_unit_concept_id | bigint  | FK reference to [concepts](#concepts) table representing the unit of duration (hours, days, weeks etc.)|                                        |          
facility_id         | bigint | FK reference to [facilities](#facilities) table               | [facilities](#facilities)              |           
admission_detail_id | bigint | FK reference to [admission_details](#admission_details) table | [admission_details](#admission_details)|           
collection_type_concept_id | bigint | FK reference to [concepts](#concepts) table representing the type of collection this record represents | [concepts](#concepts)   |          

## [contexts](#contexts)_[practitioners](#practitioners)

- Links one or more [practitioners](#practitioners) with a [contexts](#contexts) record
- Each record represents an encounter between a patient and a practitioner on a specific context
- Captures the role, if any, the practitioner played on the context (e.g., attending physician)

column                    | type   | description                                                                                                                                       | foreign key                    | required 
------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------| --------
context_id                | bigint | FK reference to [contexts](#contexts) table                                                                                                       | [contexts](#contexts)          |     x     
practitioner_id           | bigint | FK reference to [practitioners](#practitioners) table                                                                                             | [practitioners](#practitioners)|     x     
role_type_concept_id              | text   | Roles [practitioners](#practitioners) can play in an encounter                                                           |                                |           
specialty_type_concept_id | bigint | FK reference to [concepts](#concepts) table representing the practitioner's specialty type for the services/diagnoses associated with this record | [concepts](#concepts)          |

## [contexts](#contexts)

- Stores information about the context of the [clinical_codes](#clinical_codes) and [payer_reimbursements](#payer_reimbursements)
- Used to group [clinical_codes](#clinical_codes) typically occurring on the same day or at the same time (e.g., a diagnosis and a procedure, or a systolic and diastolic blood pressure)
- [contexts](#contexts) records are always linked to a collection records
- care_site_type_concept_id is used to describe the department in which the service was performed

column                            | type   | description                                                                                                                                                          | foreign key                | required 
--------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------| --------
id                                | serial | Surrogate key for record                                                                                                                                             |                            |     x     
collection_id                     | bigint | FK reference to [collections](#collections) table                                                                                                                    | [collections](#collections)|     x      
patient_id                        | bigint | FK to reference to [patients](#patients) table                                                                                                                       | [patients](#patients)      |     x      
start_date                        | date   | Start date of record (yyyy-mm-dd)                                                                                                                                    |                            |     x      
end_date                          | date   | End date of record (yyyy-mm-dd)                                                                                                                                      |                            |           
facility_id                       | bigint | FK reference to [facilities](#facilities) table                                                                                                                      | [facilities](#facilities)  |           
care_site_type_concept_id          | bigint | FK reference to [concepts](#concepts) table representing the care site type within the facility                                                                                           | [concepts](#concepts)      |           
pos_concept_id                    | bigint | FK reference to [concepts](#concepts) table representing the place of service associated with this record                                                            | [concepts](#concepts)      |           
file_type_concept_id              | bigint | FK reference to [concepts](#concepts) table representing the type of file from which the record was pulled                                                           | [concepts](#concepts)      |     x      
service_specialty_type_concept_id | bigint | FK reference to [concepts](#concepts) table representing the specialty type for the services/diagnoses associated with this record                                   | [concepts](#concepts)      |           
record_type_concept_id                   | bigint | FK reference to [concepts](#concepts) table representing the type of [contexts](#contexts) the record represents (line, claim, etc.)                                         | [concepts](#concepts)      |     x      

## [clinical_codes](#clinical_codes)

- Stores clinical codes from all types of records including procedures, diagnoses, drugs, laboratory records and other sources.  Some common vocabularies include ICD-9, ICD-10, SNOMED, Read, HCPCS, CPT, NDC, and LOINC

- Ignores semantic distinctions about the type of information represented within a vocabulary because most vocabularies contain information from more than one domain

- One record generated for each individual code in the raw data

- Extra detail can be found about a code in the [measurement_details](#measurement_details) and [drug_exposure_details](#drug_exposure_details) tables if that information exists

column                      | type   | description                                                                     | foreign key                  | required  
--------------------------- | ------ | ------------------------------------------------------------------------------- | -----------------------------| --------  
id                          | serial | Surrogate key for record                                                        |                              |     x    
collection_id               | bigint | FK reference to [collections](#collections) table                               | [collections](#collections)  |     x    
context_id                  | bigint | FK reference to [contexts](#contexts) table                                     | [contexts](#contexts)        |     x    
patient_id                  | bigint | FK reference to [patients](#patients) table                                     | [patients](#patients)        |     x    
start_date                  | date   | Start date of record (yyyy-mm-dd)                                               |                              |     x    
end_date                    | date   | End date of record (yyyy-mm-dd)                                                 |                              |         
clinical_code_concept_id    | bigint | FK reference to [concepts](#concepts) table for the code assigned to the record | [concepts](#concepts)        |     x    
quantity                    | bigint | Quantity, if available (e.g., procedures)                                       |                              |          
seq_num                     | int    | The sequence number for the variable assigned (e.g. dx3 gets sequence number 3) |                              |          
provenance_concept_id             | bigint | Additional type information (ex: primary, admitting, problem list, etc)                          | [concepts](#concepts)        |          
clinical_code_source_value        | text   | Source code from raw data                                                       |                              |     x    
clinical_code_vocabulary_id | text   | Vocabulary the clinical code comes from                                         | [vocabularies](#vocabularies)|     x 
measurement_detail_id		| bigint   | FK reference to [measurement_details](#measurement_details) table             | [measurement_details](#measurement_details)|        
drug_exposure_detail_id	 	| bigint   | FK reference to [drug_exposure_details](#drug_exposure_details) table 			   | [drug_exposure_details](#drug_exposure_details)|           

## [measurement_details](#measurement_details)

- Stores additional information related to measurements, observations, status, and specifications
- Text-based vocabularies are sufficient, but could also be mapped to LOINC and stored in the [mappings](#mappings) table  (e.g., laboratory data indexed by text names for the lab results)
- Other vocabularies should be included in their original system (e.g., oncology may be comprised of separate vocabularies for location, histology, grade, behavior, etc.)

  - This could be implemented by making variable names a vocabulary in themselves, depending on the use case


column                                | type   | description                                                                                                                                                | foreign key                      | required  
------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------| -------- 
id                                    | serial | Surrogate key for record                                                                                                                                   |                                  |     x       
patient_id                            | bigint | FK reference to [patients](#patients) table                                                                                                                | [patients](#patients)            |     x        
result_as_number                      | float  | The observation result stored as a number, applicable to observations where the result is expressed as a numeric value                                     |                                  |          
result_as_string                      | text   | The observation result stored as a string, applicable to observations where the result is expressed as verbatim text                                       |                                  |           
result_as_concept_id                  | bigint | FK reference to [concepts](#concepts) table for the result associated with the detail_concept_id (e.g., positive/negative, present/absent, low/high, etc.) | [concepts](#concepts)            |           
result_modifier_concept_id            | bigint | FK reference to [concepts](#concepts) table for result modifier (=, <, >, etc.)                                                                            | [concepts](#concepts)            |           
unit_concept_id                       | bigint | FK reference to [concepts](#concepts) table for the measurement units (e.g., mmol/L, mg/dL, etc.)                                                          | [concepts](#concepts)            |               
normal_range_low                      | float  | Lower bound of the normal reference range assigned by the laboratory                                                                                       |                                  |           
normal_range_high                     | float  | Upper bound of the normal reference range assigned by the laboratory                                                                                       |                                  |           
normal_range_low_modifier_concept_id  | bigint | FK reference to [concepts](#concepts) table for result modifier (=, <, >, etc.)                                                                            | [concepts](#concepts)            |           
normal_range_high_modifier_concept_id | bigint | FK reference to [concepts](#concepts) table for result modifier (=, <, >, etc.)                                                                            | [concepts](#concepts)            |           

## [drug_exposure_details](#drug_exposure_details)

- Designed to capture extra details about drug-specific [clinical_codes](#clinical_codes)
- The quantity of a drug is stored in the [clinical_codes](#clinical_codes) quantity field

column                    | type   | description                                                                                                               | foreign key                      | required  
------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------- | ---------------------------------| -------- 
id                        | serial | Surrogate key for record                                                                                                  |                                  |     x    
patient_id                | bigint | FK to reference to [patients](#patients) table                                                                            | [patients](#patients)            |     x    
refills                   | int    | The number of refills after the initial prescription; the initial prescription is not counted (i.e., values start with 0) |                                  |         
days_supply               | int    | The number of days of supply as recorded in the original prescription or dispensing record                                |                                  |         
number_per_day            | float  | The number of pills taken per day 														                                   |                                  |         
dose_form_concept_id      | bigint | FK reference to [concepts](#concepts) table for the form of the drug (capsule, injection, etc.)                           | [concepts](#concepts)            |         
dose_unit_concept_id      | bigint | FK reference to [concepts](#concepts) table for the units in which the dose_value is expressed                            | [concepts](#concepts)            |         
route_concept_id	      | bigint | FK reference to [concepts](#concepts) table for route in which drug is given				                               | [concepts](#concepts)            |         
dose_value                | float  | Numeric value for the dose of the drug                                                                                    |                                  |         
strength_source_value     | text   | Drug strength as reported in the raw data. This can include both dose value and units                                     |                                  |         
ingredient_source_value   | text   | Ingredient/Generic name of drug as reported in the raw data                                                               |                                  |               
drug_name_source_value    | text   | Product/Brand name of drug as reported in the raw data                                                                    |                                  |         

## [payer_reimbursements](#payer_reimbursements)

- The purpose of this table is to capture all costs reported in the course of paying for services. It is designed from a US administrative claims data perspective.
- All payer reimbursement records are linked to a record in the [contexts](#contexts) table which identifies the type of reimbursement (generally a line-level or claim-level cost)
- Note that claim-level reimbursements do not always sum to the individual line-level reimbursements, so caution should be used when querying records

column                     | type   | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | foreign key          | required   
-------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------| -------- 
id                         | serial | A unique identifier for each COST record                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                      |     x     
context_id                 | bigint | FK reference to context table                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | [contexts](#contexts)|     x     
patient_id                 | bigint | FK to reference to [patients](#patients) table                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | [patients](#patients)|     x     
clinical_code_id                 | bigint | FK reference to [clinical_codes](#clinical_codes) table to be used if a specific code is the direct cause for the reimbursement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | [clinical_codes](#clinical_codes)|          
currency_concept_id        | bigint | FK reference to [concepts](#concepts) table for the 3-letter code used to delineate international currencies (e.g., USD = US Dollar)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | [concepts](#concepts)|     x     
total_charged              | float  | The total amount charged by the provider of the good/service (e.g. hospital, physician pharmacy, dme provider) billed to a payer. This information is usually provided in claims data.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |                      |          
total_paid                 | float  | The total amount paid from all payers for the expenses of the service/device/drug. This field is calculated using the following formula: paid_by_payer + paid_by_patient + paid_by_primary. In claims data, this field is considered the calculated field the payer expects the provider to get reimbursed for the service/device/drug from the payer and from the patient, based on the payer's contractual obligations.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |                      |           
paid_by_payer              | float  | The amount paid by the Payer for the service/device/drug. In claims data, generally there is one field representing the total payment from the payer for the service/device/drug. However, this field could be a calculated field if the source data provides separate payment information for the ingredient cost and the dispensing fee. If the paid_ingredient_cost or paid_dispensing_fee fields are populated with nonzero values, the paid_by_payer field is calculated using the following formula: paid_ingredient_cost + paid_dispensing_fee. If there is more than one Payer in the source data, several cost records indicate that fact. The Payer reporting this reimbursement should be indicated under the payer_plan_id field.                                                                                                                                                 |                      |           
paid_by_patient            | float  | The total amount paid by the patient as a share of the expenses. This field is most often used in claims data to report the contracted amount the patient is responsible for reimbursing the provider for said service/device/drug. This is a calculated field using the following formula: paid_patient_copay + paid_patient_coinsurance + paid_patient_deductible. If the source data has actual patient payments (e.g. the patient payment is not a derivative of the payer claim and there is verification the patient paid an amount to the provider), then the patient payment should have it's own cost record with a payer_plan_id set to 0 to indicate the payer is actually the patient, and the actual patient payment should be noted under the total_paid field. The paid_by_patient field is only used for reporting a patient's responsibility reported on an insurance claim. |                      |                                    
paid_patient_copay         | float  | The amount paid by the patient as a fixed contribution to the expenses. paid_patient_copay does contribute to the paid_by_patient variable. The paid_patient_copay field is only used for reporting a patient's copay amount reported on an insurance claim.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |                      |           
paid_patient_coinsurance   | float  | The amount paid by the patient as a joint assumption of risk. Typically, this is a percentage of the expenses defined by the Payer Plan after the patient's deductible is exceeded. paid_patient_coinsurance does contribute to the paid_by_patient variable. The paid_patient_coinsurance field is only used for reporting a patient's coinsurance amount reported on an insurance claim.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                      |           
paid_patient_deductible    | float  | The amount paid by the patient that is counted toward the deductible defined by the Payer Plan. paid_patient_deductible does contribute to the paid_by_patient variable. The paid_patient_deductible field is only used for reporting a patient's deductible amount reported on an insurance claim.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |                      |                
paid_by_primary            | float  | The amount paid by a primary Payer through the coordination of benefits. paid_by_primary does contribute to the total_paid variable. The paid_by_primary field is only used for reporting a patient's primary insurance payment amount reported on the secondary payer insurance claim. If the source data has actual primary insurance payments (e.g. the primary insurance payment is not a derivative of the payer claim and there is verification another insurance company paid an amount to the provider), then the primary insurance payment should have it's own cost record with a payer_plan_id set to the applicable payer, and the actual primary insurance payment should be noted under the paid_by_payer field.                                                                                                                                                                |                      |           
paid_ingredient_cost       | float  | The amount paid by the Payer to a pharmacy for the drug, excluding the amount paid for dispensing the drug. paid_ingredient_cost contributes to the paid_by_payer field if this field is populated with a nonzero value.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |                      |           
paid_dispensing_fee        | float  | The amount paid by the Payer to a pharmacy for dispensing a drug, excluding the amount paid for the drug ingredient. paid_dispensing_fee contributes to the paid_by_payer field if this field is populated with a nonzero value.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |                      |           
information_period_id      | float  | FK reference to the [information_periods](#information_periods) table                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |                      |           
amount_allowed             | float  | The contracted amount agreed between the payer and provider. This information is generally available in claims data. This is similar to the total_paid amount in that it shows what the payer expects the provider to be reimbursed after the payer and patient pay. This differs from the total_paid amount in that it is not a calculated field, but a field available directly in claims data. Use case: This will capture non-covered services. Non-covered services are indicated by an amount allowed and patient responsibility variables (copay, coinsurance, deductible) will be equal $0 in the source data. This means the patient is responsible for the total_charged value. The amount_allowed field is payer specific and the payer should be indicated by the payer_plan_id field.                                                                                            |                      |           

## [costs](#costs)

- Used to capture all non reimbursement costs
- Examples of things captured in this table are things like cost-to-charge ratio, calculated cost (for situations where the ETL process calculates a cost based on the available data), reported cost (where the ETL process imputes a cost from another source), and some other things that may become apparent with more use cases.

column       | type   | description                                                                                        | foreign key | required  
------------ | ------ | -------------------------------------------------------------------------------------------------- | ----------- | -------- 
id           | serial | A unique identifier for each geographic location                                                   |             |     x    
context_id   | bigint | FK reference to context table | [contexts](#contexts)|     x     
patient_id   | bigint | FK to reference to [patients](#patients) table   | [patients](#patients)|     x     
clinical_code_id | bigint | FK reference to [clinical_codes](#clinical_codes) table to be used if a specific code is the direct cause for the reimbursement | [clinical_codes](#clinical_codes)|   
currency_concept_id | bigint | FK reference to [concepts](#concepts) table for the 3-letter code used to delineate international currencies (e.g., USD = US Dollar) | [concepts](#concepts)|     x   
cost_base | float | Defines the basis for the cost in the table (e.g., 2013 for a specific cost-to-charge ratio, or a specific cost from an external cost | |     x   
value 		 | float  | Cost value 																									|			 |     x   
value_type_concept_id | bigint  | FK reference to [concepts](#concepts) table to concept that defines the type of economic information in the value field (e.g., cost-to-charge ratio, calculated cost, reported cost) | [concepts](#concepts) |     x   

## [addresses](#addresses)

- Used to store location information for [patients](#patients), [practitioners](#practitioners), and [facilities](#facilities)
- One record for each geographic location in the data

column       | type   | description                                                                                        | foreign key | required  
------------ | ------ | -------------------------------------------------------------------------------------------------- | ----------- | -------- 
id           | serial | A unique identifier for each geographic location                                                   |             |     x    
address_1    | text   | Typically used for street address                                                                  |             |          
address_2    | text   | Typically used for additional detail such as building, suite, floor, etc.                          |             |           
city         | text   | The city field as it appears in the source data 								                   |             |           
state        | text   | The state field as it appears in the source data 												   |             |           
zip          | text   | The zip or postal code                                                                             |             |           
county       | text   | The county, if available                                                                                         |             |             
census_tract | text   | The census tract if available                                                                      |             |           
hsa          | text   | The Health Service Area, if available (originally defined by the National Center for Health Statistics)                                                              |             |            
country       | text   | The country if necessary                                                               |             |            

## [deaths](#deaths)

- Stores mortality information including date of death and cause(s) of death
- Commonly populated from beneficiary or similar administrative data associated with the medical record
- Deaths identified from diagnosis codes or discharge status are not necessary since such records are in the [clinical_codes](#clinical_codes) and [admission_details](#admission_details) tables and can be queried separately

column                | type   | description                                                                                                 | foreign key                    | required          
--------------------- | ------ | ----------------------------------------------------------------------------------------------------------- | -------------------------------| --------  
id                    | serial | Surrogate key for record                                                                                    |                                |	    x     
patient_id            | bigint | FK reference to [patients](#patients) table                                                                 | [patients](#patients)          |	    x       
date                  | date   | Date of death (yyyy-mm-dd)                                                                                  |                                |	    x     
cause_concept_id      | bigint | FK reference to [concepts](#concepts) table for cause of death (typically ICD-9 or ICD-10 code)             | [concepts](#concepts)          |	         
cause_type_concept_id | bigint | FK reference to [concepts](#concepts) table for the type of cause of death (e.g. primary, secondary, etc. ) | [concepts](#concepts)          |	         
practitioner_id       | bigint | FK reference to [practitioners](#practitioners) table                                                       | [practitioners](#practitioners)|	           

## [information_periods](#information_periods)

- Captures periods for which information in each table is relevant for each person
- Could include enrollment types (e.g., Part A, Part B, HMO) or just "observable" (as with up-to-standard data in CPRD)
- One row per patient per enrollment/information period type

column                      | type   | description                                                                                                                                  | foreign key          | required      
--------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------| --------   
id                          | serial | Surrogate key for record                                                                                                                     |                      |     x      
patient_id                  | bigint | FK reference to [patients](#patients) table                                                                                                  | [patients](#patients)|     x    
start_date                  | date   | Start date of record (yyyy-mm-dd)                                                                                                            |                      |     x         
end_date                    | date   | End date of record (yyyy-mm-dd)                                                                                                              |                      |     x     
information_type_concept_id | bigint | FK reference to [concepts](#concepts) table representing the information type (e.g., insurance coverage, hospital data, up-to-standard date) | [concepts](#concepts)|     x    

## [admission_details](#admission_details)

- Captures details about admissions and emergency department encounters that cannot be stored in the [clinical_codes](#clinical_codes), [contexts](#contexts), or [collections](#collections) tables
- One row per admission
- Each admission record in the [collections](#collections) table will link to this table

column                | type   | description                                                                                                              | foreign key          | required    
--------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------ | ---------------------| -------- 
id                    | serial | Surrogate key for record                                                                                                 |                      |     x     
patient_id            | bigint | FK reference to [patients](#patients) table                                                                              | [patients](#patients)|     x    
admission_date        | date   | Date of admission (yyyy-mm-dd)                                                                                           |                      |     x       
discharge_date        | date   | Date of discharge (yyyy-mm-dd)                                                                                           |                      |          
admit_source_concept_id       | bigint | Database specific code indicating source of admission (e.g., ER visit, transfer, etc.)                                   |                      |         
discharge_location_concept_id | bigint | Database specific code indicating discharge location (e.g., death, home, transfer, long-term care, etc.)                |                      |
admission_type_concept_id       | bigint | FK reference to [concepts](#concepts) table representing the type of admission the record is (Emergency, Elective, etc.) | [concepts](#concepts)|

## [concepts](#concepts)

- Adapted from OMOP concept table (could add other fields, like domain, if needed)
- Can be created *de novo* for each data source or could use a different source like the [National Library of Medicine Metathesaurus](https://www.nlm.nih.gov/research/umls/knowledge_sources/metathesaurus/)
- The [mappings](#mappings) table can be used to establish relationships among concept ids

column        | type   | description                                                                      | foreign key                  | required   
------------- | ------ | -------------------------------------------------------------------------------- | -----------------------------| --------  
id            | serial | Surrogate key for record (this is the concept_id)                                |                              |     x       
vocabulary_id | text   | Unique text-string identifier of the vocabulary (see OMOP or UMLS)               | [vocabularies](#vocabularies)|     x    
concept_code  | text   | Actual code as text string from the source vocabulary (e.g., "410.00" for ICD-9) |                              |     x     
concept_text  | text   | Text descriptor associated with the concept_code                                 |                              |     x     

## [vocabularies](#vocabularies)

- A list of vocabularies, currently adapted from the OMOP vocabulary table (e.g., ICD9)

column               | type | description                                                         | foreign key | required
-------------------- | ---- | ------------------------------------------------------------------- | ----------- | --------
id                   | text | Short name of the vocabulary which acts as a natural key for record |             |     x
omopv4_vocabulary_id | int  | Old ID used in OMOPv4                                               |             |     x
vocabulary_name      | text | Full name of the vocabulary                                         |             |     x

## [mappings](#mappings)

- A set of relationships, currently adapted from the OMOP concept_relationship table
- This can be used to establish relationships between database-specific information and standardized information.
- It is preferable to store the raw data in the [concepts](#concepts) table and establish a mapping to standard concepts in this table.  
	- For example, if sex were coded as "male" and "female", these terms would be stored in the [concepts](#concepts) table, and would be linked to standard concepts (if any) in the [mappings](#mappings) table
	- This moves such "hidden" mappings from the ETL process to the data itself, makes ETL easier, and increases transparency and reproducibility of studies

column               | type   | description                                                              | foreign key                   | required
-------------------- | -----  | ------------------------------------------------------------------------ | ----------------------------- | --------
concept_id_1         | bigint | FK reference to [concepts](#concepts) table for the source concept       | [concepts](#concepts)         |     x
relationship_id      | text   | The type or nature of the relationship (e.g., "is_a")                    |                               |     x
concept_id_2         | bigint | FK reference to [concepts](#concepts) table for the destination concept  | [concepts](#concepts)         |     x
