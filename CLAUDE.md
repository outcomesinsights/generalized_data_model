# generalized_data_model

> Defines the Generalized Data Model (GDM), a common data model for healthcare claims and EHR data, influenced by OMOP/OHDSI.

## Status

- **Active**
- Last meaningful work: 2026-02

## Tech Stack

- Language: Ruby
- Framework: None
- Key dependencies: mdl (markdown linting)

## Purpose

The GDM provides a standardized schema for storing clinical/healthcare data from administrative claims and EHR systems. It defines tables for patients, practitioners, facilities, clinical codes, costs, and related entities. The README.md is the source of truth for the schema definition, which Ruby scripts parse to generate machine-readable formats (YAML, CSV, Sequel migrations).

## Key Entry Points

- `README.md` - The canonical schema definition (tables, columns, types, foreign keys)
- `converter.rb` - Parses README.md to generate schema.csv and schema.yml
- `convert_to_schema.rb` - Parses README.md to generate Sequel migration (schema.rb)
- `generate_wide_tables.sql` - SQL to create denormalized "observations" table from GDM

## Commands

```bash
# Generate schema artifacts from README.md
bundle exec ruby converter.rb
bundle exec ruby convert_to_schema.rb

# Lint markdown
bundle exec mdl README.md
```

## Relationships

- **Depends on**: OMOP/OHDSI vocabulary concepts for foreign keys
- **Feeds into**: ConceptQL, setlr (ETL tooling), downstream healthcare analytics

## Domain Concepts

- **clinical_codes**: Central table storing diagnoses, procedures, drugs, labs (ICD, CPT, NDC, LOINC, etc.)
- **collections**: Groups contexts; represents claims or visits
- **contexts**: Groups clinical_codes; represents claim lines or encounter events
- **observations**: Denormalized wide table joining clinical_codes with related detail tables
