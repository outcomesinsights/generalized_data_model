require 'pathname'

table = nil
collect = false
schema = {}

artifacts_dir = Pathname.new("artifacts") + "gdm"
artifacts_dir.mkpath

class SequelMigrationIO
  attr_reader :indent, :io

  def initialize
    @io = StringIO.new
    @indent = 0
    open_block "Sequel.migration do"
    open_block "change do"
  end

  def puts(*args)
    io.print(" " * indent)
    io.puts(*args)
  end

  def close_block(opts = {})
    decrease_indent
    puts("end")
    unless opts[:no_blank]
      io.puts
    end
  end

  def open_block(*args)
    puts(*args)
    increase_indent
  end

  def increase_indent
    @indent += 2
  end

  def decrease_indent
    @indent -= 2
  end

  def finish
    while(@indent > 0)
      close_block(no_blank: true)
    end
  end

  def string
    io.string
  end
end

def extract(link)
  return nil if link.nil? || link.empty?
  return "contexts_practitioners" if link =~ /contexts/ && link =~ /practitioners/
  md = /\[(.+)\]/.match(link)
  md.to_a[1] if md
end

def is_primary?(column, type)
  type.to_sym == :serial || column.to_sym == :id
end

def convert(name, type)
  opts = {}

  db_type = case type.to_sym
  when :int
    "Integer"
  when :text
    opts[:text] = true
    "String"
  when :bigint, :serial
    opts[:type] = :Bigint
    "Integer"
  when :float
    "Float"
  when :date
    "Date"
  when :boolean
    "TrueClass"
  else
    raise "Unknown type #{type}"
  end

  if is_primary?(name, type)
    if opts[:text]
      opts[:primary_key] = true
    else
      opts[:type] = :Bigint
      db_type = "primary_key"
    end
  end

  [db_type, opts]
end

schema_io = SequelMigrationIO.new
fks = {}

File.foreach('README.md') do |line|
  line.chomp!
  case line
  when /^\###\s*(.+)/
    table = extract(Regexp.last_match.to_a.last).to_sym
    schema_io.open_block "create_table(#{table.inspect}) do"
    next
  when /-{4,}/
    collect = true
    next
  when ''
    if collect
      schema_io.close_block
    end
    collect = false
  end

  if collect
    line.gsub!(/(^\||\|$)/, '')
    name, type, comment, foreign_key, required = line.split("|").map(&:strip)
    #p [name, type, comment, foreign_key, required]
    name = name.to_sym
    type = type.to_sym
    foreign_key = extract(foreign_key)
    type, column_opts = *convert(name, type)
    column_opts.merge!(comment: comment)
    column_opts.merge!(null: false) if required && !required.strip.empty?
    if foreign_key
      (fks[table] ||= {})[name] = foreign_key
    end
    schema_io.puts "#{type} #{name.inspect}#{column_opts.empty? ? '' : ", #{column_opts.inspect}"}"
  end
end

schema_io.finish


File.write(artifacts_dir + "schema.rb", schema_io.string)
#File.write(artifacts_dir + "foreign_keys.rb", fk_io.string)
