class Rdf::Builders::EquivalentClassHandler < Rdf::Builders::BaseHandler
  def initialize(key)
    @key = key
  end

  def call(predicate, objects)
    sub_hash = @context.convert_to_hash(objects.first)
    @context.attributes[@key] = sub_hash["owl:onDatatype"].first.to_s if sub_hash.key?("owl:onDatatype")
  end
end
