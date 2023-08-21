module Rdf::Builders::Traversable
  attr_accessor :graph

  def traverse(subject)
    graph.each.lazy.select do |statement|
      statement.subject == subject
    end
  end

  def convert_to_hash(subject)
    hash = {}
    traverse(subject).each do |statement|
      key = statement.predicate.pname
      hash[key] = [] unless hash.key?(key)
      hash[key] << statement.object
    end
    hash
  end
end
