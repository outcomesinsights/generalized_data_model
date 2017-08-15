require "yaml"

class Entity
  attr :entity_info, :table_name

  def initialize(table_name, entity_info)
    @table_name = table_name
    @entity_info = entity_info
  end

  class Column
    attr :column_info, :column_name

    def initialize(column_name, column_info)
      @column_name = column_name
      @column_info = column_info
    end

    def required?
      !column_info[:null]
    end

    def primary_key?
      column_info[:primary_key]
    end

    def foreign_key?
      foreign_key
    end

    def foreign_key
      column_info[:foreign_key]
    end

    def type
      column_info[:type]
    end

    def to_plain_entity
      parts = []
      parts << '*' if primary_key?
      parts << '+' if foreign_key?
      parts << column_name
      parts << ' { label: "'
      parts << type.to_s
      parts << ", required" if required?
      parts << '" }'
      parts.join
    end
  end

  def columns
    @columns ||= @entity_info.map { |name, col| Column.new(name, col) }
  end

  def relationships
    columns.select(&:foreign_key?).map do |col|
      "#{table_name} ?--* #{col.foreign_key}"
    end.uniq
  end

  def to_plain_entity
    output = ["[#{table_name}]"]
    output += columns.map do |column|
      column.to_plain_entity
    end
    output += relationships
    output.join("\n")
  end
end

schema = YAML::load_file(ARGV[0])

diagram_output = schema.map do |table_name, entity_info|
  Entity.new(table_name, entity_info)
end.map(&:to_plain_entity).join("\n\n")

File.write("artifacts/erd.txt", diagram_output)

system("cabal update ; cabal install erd --allow-newer ; ~/.cabal/bin/erd -i artifacts/erd.txt -o erd.png")

