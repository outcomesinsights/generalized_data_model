require_relative "test_helper"

class GdmHelpersTest < Minitest::Test
  # --- extract ---

  def test_extract_simple_link
    assert_equal "patients", GdmHelpers.extract("[patients](#patients)")
  end

  def test_extract_external_link
    assert_equal "concept", GdmHelpers.extract("[concept](https://ohdsi.github.io/CommonDataModel/cdm54.html#CONCEPT)")
  end

  def test_extract_nil
    assert_nil GdmHelpers.extract(nil)
  end

  def test_extract_empty_string
    assert_nil GdmHelpers.extract("")
  end

  def test_extract_no_brackets
    assert_nil GdmHelpers.extract("no link here")
  end

  def test_extract_contexts_practitioners_special_case
    # The link text contains both "contexts" and "practitioners"
    assert_equal "contexts_practitioners",
      GdmHelpers.extract("[context_practitioners](#contexts_practitioners)")
  end

  def test_extract_vocabulary_link
    assert_equal "vocabulary", GdmHelpers.extract("[vocabulary](#vocabulary)")
  end

  def test_extract_addresses_link
    assert_equal "addresses", GdmHelpers.extract("[addresses](#addresses)")
  end

  # --- is_primary? ---

  def test_is_primary_serial_type
    assert GdmHelpers.is_primary?("id", "serial")
  end

  def test_is_primary_id_column_bigint
    assert GdmHelpers.is_primary?("id", "bigint")
  end

  def test_is_primary_non_primary_column
    refute GdmHelpers.is_primary?("name", "text")
  end

  def test_is_primary_accepts_symbols
    assert GdmHelpers.is_primary?(:id, :serial)
  end

  def test_is_primary_non_id_serial
    # serial type but not named id — still primary
    assert GdmHelpers.is_primary?("other_col", "serial")
  end

  def test_is_primary_id_column_with_text_type
    # named id but text type — still primary
    assert GdmHelpers.is_primary?("id", "text")
  end
end
