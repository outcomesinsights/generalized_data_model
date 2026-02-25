# Mini Schema

## GDM Tables

### [patients](#patients)

- Test table for patients

| column | type | description | foreign key (FK) | required |
| ------ | ---- | ----------- | ---------------- | -------- |
| id | serial | Surrogate key for record | | x |
| gender_concept_id | bigint | FK to concept | [concept](https://ohdsi.github.io/CommonDataModel/cdm54.html#CONCEPT) | |
| birth_date | date | Date of birth | | x |
| name | text | Patient name | | |
| practitioner_id | bigint | FK to practitioners | [practitioners](#practitioners) | |
| weight | float | Patient weight | | |
| is_active | boolean | Whether patient is active | | x |

### [practitioners](#practitioners)

- Test table for practitioners

| column | type | description | foreign key (FK) | required |
| ------ | ---- | ----------- | ---------------- | -------- |
| id | serial | Surrogate key for record | | x |
| practitioner_name | text | Practitioner name | | |
| specialty_concept_id | bigint | FK to concept | [concept](https://ohdsi.github.io/CommonDataModel/cdm54.html#CONCEPT) | |
| address_id | bigint | FK to addresses | [addresses](#addresses) | |

### [contexts_practitioners](#contexts_practitioners)

- Test join table

| column | type | description | foreign key (FK) | required |
| ------ | ---- | ----------- | ---------------- | -------- |
| id | serial | Surrogate key | | x |
| context_id | bigint | FK to contexts | [contexts](#contexts) | x |
