require_relative "test_helper"
require "csv"
require "psych"
require "tmpdir"
require "fileutils"

class ConverterTest < Minitest::Test
  FIXTURE = File.expand_path("fixtures/mini_schema.md", __dir__)
  CONVERTER = File.expand_path("../converter.rb", __dir__)
  PROJECT_ROOT = File.expand_path("..", __dir__)

  def setup
    @tmpdir = Dir.mktmpdir("gdm_converter_test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def run_converter
    # Run converter.rb with our fixture instead of README.md
    # We copy the fixture to README.md in a temp working directory
    FileUtils.cp(FIXTURE, File.join(@tmpdir, "README.md"))
    FileUtils.cp_r(File.join(PROJECT_ROOT, "lib"), @tmpdir)

    # Patch converter.rb to use relative paths (it already does)
    FileUtils.cp(CONVERTER, @tmpdir)

    output = nil
    Dir.chdir(@tmpdir) do
      output = `ruby converter.rb 2>&1`
    end
    assert $?.success?, "converter.rb failed: #{output}"
    @tmpdir
  end

  def test_generates_csv
    run_converter
    csv_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.csv")
    assert File.exist?(csv_path), "schema.csv not generated"

    rows = CSV.read(csv_path, headers: true)
    assert rows.length > 0, "CSV should have data rows"
    assert_equal %w[table column type comment foreign_key required], rows.headers
  end

  def test_csv_has_correct_tables
    run_converter
    csv_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.csv")
    rows = CSV.read(csv_path, headers: true)

    tables = rows.map { |r| r["table"] }.uniq
    assert_includes tables, "patients"
    assert_includes tables, "practitioners"
    assert_includes tables, "contexts_practitioners"
  end

  def test_csv_patients_columns
    run_converter
    csv_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.csv")
    rows = CSV.read(csv_path, headers: true)

    patient_rows = rows.select { |r| r["table"] == "patients" }
    columns = patient_rows.map { |r| r["column"] }
    assert_includes columns, "id"
    assert_includes columns, "gender_concept_id"
    assert_includes columns, "birth_date"
    assert_includes columns, "name"
    assert_includes columns, "weight"
    assert_includes columns, "is_active"
  end

  def test_csv_captures_types
    run_converter
    csv_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.csv")
    rows = CSV.read(csv_path, headers: true)

    id_row = rows.find { |r| r["table"] == "patients" && r["column"] == "id" }
    assert_equal "serial", id_row["type"]

    name_row = rows.find { |r| r["table"] == "patients" && r["column"] == "name" }
    assert_equal "text", name_row["type"]

    weight_row = rows.find { |r| r["table"] == "patients" && r["column"] == "weight" }
    assert_equal "float", weight_row["type"]
  end

  def test_csv_captures_foreign_keys
    run_converter
    csv_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.csv")
    rows = CSV.read(csv_path, headers: true)

    fk_row = rows.find { |r| r["table"] == "patients" && r["column"] == "gender_concept_id" }
    assert_equal "concept", fk_row["foreign_key"]

    prac_fk = rows.find { |r| r["table"] == "patients" && r["column"] == "practitioner_id" }
    assert_equal "practitioners", prac_fk["foreign_key"]
  end

  def test_csv_captures_required
    run_converter
    csv_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.csv")
    rows = CSV.read(csv_path, headers: true)

    id_row = rows.find { |r| r["table"] == "patients" && r["column"] == "id" }
    assert_equal "x", id_row["required"]

    name_row = rows.find { |r| r["table"] == "patients" && r["column"] == "name" }
    assert_empty name_row["required"].to_s.strip
  end

  def test_generates_yaml
    run_converter
    yml_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.yml")
    assert File.exist?(yml_path), "schema.yml not generated"

    schema = Psych.safe_load(File.read(yml_path), permitted_classes: [Symbol])
    assert schema.key?(:patients), "YAML should have patients table"
    assert schema[:patients].key?(:columns), "patients should have columns"
  end

  def test_generates_arrayed_yaml
    run_converter
    yml_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema_arrayed.yml")
    assert File.exist?(yml_path), "schema_arrayed.yml not generated"

    schema = Psych.safe_load(File.read(yml_path), permitted_classes: [Symbol])
    assert_kind_of Array, schema
    table_names = schema.map { |t| t[:name] }
    assert_includes table_names, :patients
    assert_includes table_names, :practitioners
  end

  def test_yaml_column_types
    run_converter
    yml_path = File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.yml")
    schema = Psych.safe_load(File.read(yml_path), permitted_classes: [Symbol])

    id_col = schema[:patients][:columns][:id]
    assert_equal true, id_col[:primary_key]
    assert_equal :Bigint, id_col[:type]

    name_col = schema[:patients][:columns][:name]
    assert_equal "String", name_col[:type]

    birth_col = schema[:patients][:columns][:birth_date]
    assert_equal "Date", birth_col[:type]
  end
end
