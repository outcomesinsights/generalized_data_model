module GdmHelpers
  # Extract table name from a markdown link like [patients](#patients)
  # Special-cases contexts_practitioners which spans two words
  def self.extract(link)
    return nil if link.nil? || link.empty?
    return "contexts_practitioners" if link =~ /contexts/ && link =~ /practitioners/
    md = /\[(.+)\]/.match(link)
    md.to_a[1] if md
  end

  # Returns true if this column is a primary key (serial type or named 'id')
  def self.is_primary?(column, type)
    type.to_sym == :serial || column.to_sym == :id
  end
end
