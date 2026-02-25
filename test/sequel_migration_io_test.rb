require_relative "test_helper"
require "stringio"

# Load SequelMigrationIO class from convert_to_schema.rb without executing the script
# We need to extract just the class definition
require_relative "../convert_to_schema_class"

class SequelMigrationIOTest < Minitest::Test
  def setup
    @sio = SequelMigrationIO.new
  end

  def test_initial_indent
    # After initialize: open_block "Sequel.migration do" (indent 0->2)
    # then open_block "change do" (indent 2->4)
    assert_equal 4, @sio.indent
  end

  def test_initial_output_has_sequel_migration_header
    output = @sio.string
    assert_includes output, "Sequel.migration do"
    assert_includes output, "  change do"
  end

  def test_puts_respects_indent
    @sio.puts "hello"
    assert_includes @sio.string, "    hello\n"
  end

  def test_open_block_increases_indent
    initial = @sio.indent
    @sio.open_block "create_table(:test) do"
    assert_equal initial + 2, @sio.indent
    assert_includes @sio.string, "    create_table(:test) do\n"
  end

  def test_close_block_decreases_indent_and_writes_end
    @sio.open_block "create_table(:test) do"
    @sio.close_block
    assert_equal 4, @sio.indent
    assert_includes @sio.string, "    end\n"
  end

  def test_close_block_with_no_blank
    @sio.open_block "create_table(:test) do"
    @sio.puts "Integer :col"
    @sio.close_block(no_blank: true)
    # Should not have a blank line after end
    lines = @sio.string.lines
    end_line_idx = lines.rindex { |l| l.strip == "end" }
    # Next line (if any) should not be blank, or it's the last line
    if end_line_idx && end_line_idx < lines.length - 1
      refute_equal "\n", lines[end_line_idx + 1]
    end
  end

  def test_finish_closes_all_blocks
    @sio.open_block "create_table(:test) do"
    @sio.finish
    assert_equal 0, @sio.indent
    # Should have closing "end" for each open block
    end_count = @sio.string.scan(/^\s*end\s*$/).length
    assert_equal 3, end_count  # test block + change do + Sequel.migration do
  end

  def test_increase_decrease_indent
    initial = @sio.indent
    @sio.increase_indent
    assert_equal initial + 2, @sio.indent
    @sio.decrease_indent
    assert_equal initial, @sio.indent
  end

  def test_full_table_round_trip
    @sio.open_block "create_table(:patients) do"
    @sio.puts "primary_key :id, {type: :Bigint}"
    @sio.puts "String :name"
    @sio.close_block
    @sio.finish

    output = @sio.string
    assert_includes output, "Sequel.migration do\n"
    assert_includes output, "  change do\n"
    assert_includes output, "    create_table(:patients) do\n"
    assert_includes output, "      primary_key :id, {type: :Bigint}\n"
    assert_includes output, "      String :name\n"
    assert_includes output, "    end\n"
  end
end
