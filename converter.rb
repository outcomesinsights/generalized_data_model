require 'psych'
require 'pathname'
require 'csv'

table = nil
collect = false
schema = {}

artifacts_dir = Pathname.new("artifacts")
artifacts_dir.mkpath

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
  db_type = case type.to_sym
  when :int
    "Integer"
  when :text
    "String"
  when :bigint, :serial
    :Bigint
  when :float
    "Float"
  when :date
    "Date"
  else
    raise "Unknown type #{type}"
  end

  result = { type: db_type }
  result.merge!(primary_key: true) if is_primary?(name, type)
  result
end

CSV.open(artifacts_dir + "gdm.csv", "w") do |csv|
  csv << %w(table column type comment foreign_key required)
  File.foreach('README.md') do |line|
    line.chomp!
    case line
    when /^\##\s*(.+)/
      table = extract(Regexp.last_match.to_a.last).to_sym
      next
    when /-{4,}/
      collect = true
      next
    when ''
      collect = false
    end
    if collect
      line.gsub!(/(^\||\|$)/, '')
      name, type, comment, foreign_key, required = line.split("|").map(&:strip)
      #p [name, type, comment, foreign_key, required]
      name = name.to_sym
      type = type.to_sym
      foreign_key = extract(foreign_key)
      csv << [table, name, type, comment, foreign_key, required]
      schema[table] ||= {}
<<<<<<< HEAD
      schema[table][name] = convert(type, name).merge(comment: comment)
=======
      schema[table][name] = convert(name, type).merge(comment: comment)
>>>>>>> e97ac286ecdf2d5e7d5dc8c29436ef434c98566e
      schema[table][name].merge!(foreign_key: foreign_key) unless foreign_key.nil? || foreign_key.empty?
      schema[table][name].merge!(null: false) if required && !required.strip.empty?
    end
  end
end

File.write(artifacts_dir + "gdm.yml", schema.to_yaml)
