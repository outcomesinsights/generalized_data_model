DROP TABLE IF EXISTS observations;
CREATE TABLE observations AS
	SELECT 
		cc.id,
		cc.context_id,
		cc.patient_id,
		cc.start_date,
		cc.end_date,
		cc.clinical_code_concept_id,
		cc.quantity,
		cc.seq_num,
		cc.provenance_concept_id,
		cc.clinical_code_source_value,
		cc.clinical_code_vocabulary_id,
		ctx.start_date AS context_start_date,
		ctx.end_date AS context_end_date,
		ctx.facility_id AS context_facility_id,
		ctx.care_site_type_concept_id,
		ctx.pos_concept_id,
		ctx.source_type_concept_id,
		ctx.service_specialty_type_concept_id,
		ctx.record_type_concept_id,
		col.id AS collection_id,
		col.start_date AS collection_start_date,
		col.end_date AS collection_end_date,
		col.duration,
		col.duration_unit_concept_id,
		col.facility_id AS collection_facility_id,
		col.collection_type_concept_id,
		ded.refills,
		ded.days_supply,
		ded.number_per_day,
		ded.dose_form_concept_id,
		ded.dose_unit_concept_id,
		ded.route_concept_id,
		ded.dose_value,
		ded.strength_source_value,
		ded.ingredient_source_value,
		ded.drug_name_source_value,
		ad.admission_date AS admit_admission_date,
		ad.discharge_date AS admit_discharge_date,
		ad.admit_source_concept_id,
		ad.discharge_location_concept_id,
		ad.admission_type_concept_id,
		md.result_as_number,
		md.result_as_string,
		md.result_as_concept_id,
		md.result_modifier_concept_id,
		md.unit_concept_id,
		md.normal_range_low,
		md.normal_range_high,
		md.normal_range_low_modifier_concept_id,
		md.normal_range_high_modifier_concept_id
	FROM clinical_codes AS cc
	LEFT JOIN contexts AS ctx ON (cc.context_id = ctx.id)
	LEFT JOIN collections AS col ON (cc.context_id = col.id)
	LEFT JOIN drug_exposure_details AS ded ON (cc.drug_exposure_detail_id = ded.id)
	LEFT JOIN admission_details AS ad ON (col.admission_detail_id = ad.id)
	LEFT JOIN measurement_details AS md ON (cc.measurement_detail_id = md.id)
;
CREATE INDEX ON observations (clinical_code_vocabulary_id, clinical_code_concept_id, patient_id);
CLUSTER observations USING observations_clinical_code_vocabulary_id_clinical_code_conc_idx;
CREATE INDEX ON observations (patient_id, clinical_code_concept_id, start_date);
CREATE INDEX ON observations (patient_id, start_date, clinical_code_concept_id);
CREATE INDEX ON observations (clinical_code_concept_id, patient_id, start_date);
CREATE INDEX ON observations (clinical_code_concept_id, context_id);
CREATE INDEX ON observations (provenance_concept_id, source_type_concept_id);
CREATE INDEX ON observations (context_id);
VACUUM ANALYZE observations;

DROP TABLE IF EXISTS supplemented_payer_reimbursements;
CREATE TABLE supplemented_payer_reimbursements AS
	SELECT
		pr.*,
		cc.collection_id AS collection_id,
		cc.clinical_code_concept_id,
		cc.clinical_code_source_value,
		cc.clinical_code_vocabulary_id,
		ctx.start_date,
		ctx.end_date,
		ctx.source_type_concept_id,
		ctx.record_type_concept_id
	FROM payer_reimbursements AS pr
	LEFT JOIN clinical_codes AS cc ON (cc.id = pr.clinical_code_id)
	LEFT JOIN contexts AS ctx ON (ctx.id = pr.context_id)
;
CREATE INDEX ON supplemented_payer_reimbursements (patient_id, start_date);
CLUSTER supplemented_payer_reimbursements USING supplemented_payer_reimbursements_patient_id_start_date_idx;