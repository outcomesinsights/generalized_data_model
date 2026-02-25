require "stringio"

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
