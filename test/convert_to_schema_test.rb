require_relative "test_helper"
require "tmpdir"
require "fileutils"

class ConvertToSchemaTest < Minitest::Test
  FIXTURE = File.expand_path("fixtures/mini_schema.md", __dir__)
  SCRIPT = File.expand_path("../convert_to_schema.rb", __dir__)
  PROJECT_ROOT = File.expand_path("..", __dir__)

  def setup
    @tmpdir = Dir.mktmpdir("gdm_schema_test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def run_convert_to_schema
    FileUtils.cp(FIXTURE, File.join(@tmpdir, "README.md"))
    FileUtils.cp_r(File.join(PROJECT_ROOT, "lib"), @tmpdir)
    FileUtils.cp(File.join(PROJECT_ROOT, "convert_to_schema_class.rb"), @tmpdir)
    FileUtils.cp(SCRIPT, @tmpdir)

    output = nil
    Dir.chdir(@tmpdir) do
      output = `ruby convert_to_schema.rb 2>&1`
    end
    assert $?.success?, "convert_to_schema.rb failed: #{output}"

    File.read(File.join(@tmpdir, "artifacts", "schemas", "gdm", "schema.rb"))
  end

  def test_generates_schema_rb
    schema = run_convert_to_schema
    assert schema.length > 0, "schema.rb should not be empty"
  end

  def test_has_sequel_migration_wrapper
    schema = run_convert_to_schema
    assert_includes schema, "Sequel.migration do"
    assert_includes schema, "change do"
  end

  def test_creates_patients_table
    schema = run_convert_to_schema
    assert_includes schema, "create_table(:patients) do"
  end

  def test_creates_practitioners_table
    schema = run_convert_to_schema
    assert_includes schema, "create_table(:practitioners) do"
  end

  def test_creates_contexts_practitioners_table
    schema = run_convert_to_schema
    assert_includes schema, "create_table(:contexts_practitioners) do"
  end

  def test_primary_key_columns
    schema = run_convert_to_schema
    # id with serial type should become primary_key with Bigint
    assert_match(/primary_key :id.*Bigint/, schema)
  end

  def test_foreign_key_to_concept
    schema = run_convert_to_schema
    # FK to concept should use key: :concept_id
    assert_match(/foreign_key :gender_concept_id, :concept.*key: :concept_id/, schema)
  end

  def test_foreign_key_to_regular_table
    schema = run_convert_to_schema
    # FK to practitioners should use key: :id
    assert_match(/foreign_key :practitioner_id, :practitioners.*key: :id/, schema)
  end

  def test_date_column
    schema = run_convert_to_schema
    assert_match(/Date :birth_date/, schema)
  end

  def test_text_column_as_string
    schema = run_convert_to_schema
    assert_match(/String :name/, schema)
  end

  def test_float_column
    schema = run_convert_to_schema
    assert_match(/Float :weight/, schema)
  end

  def test_boolean_column
    schema = run_convert_to_schema
    assert_match(/TrueClass :is_active/, schema)
  end

  def test_null_false_on_required_columns
    schema = run_convert_to_schema
    # birth_date is required
    assert_match(/Date :birth_date.*null: false/, schema)
  end

  def test_proper_closing
    schema = run_convert_to_schema
    # Should end with properly nested end statements
    lines = schema.strip.lines.map { |l| l.strip }
    assert_equal "end", lines[-1]
    assert_equal "end", lines[-2]
  end
end
