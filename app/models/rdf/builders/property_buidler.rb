class Rdf::Builders::PropertyBuidler < Rdf::Builders::BaseBuilder
  include Rdf::Builders::Traversable
  include Rdf::Builders::Context

  IGNORE_PREDICATES = %w(rdf:type
                         dc:hasVersion
                         dc:issued
                         dc:modified
                         rdfs:isDefinedBy
                         schema:domainIncludes).freeze

  def initialize
    register_handler("rdfs:label", Rdf::Builders::LangLiteralHandler.new(:labels))

    register_handler("rdfs:comment", Rdf::Builders::LangLiteralHandler.new(:comments))
    alias_handler "dc:description", "rdfs:comment"
    alias_handler "skos:note", "rdfs:comment"

    register_handler("rdfs:domain", Rdf::Builders::RangeHandler.new(:domains))

    register_handler("rdfs:range", Rdf::Builders::RangeHandler.new(:ranges))

    register_handler("rdfs:subPropertyOf", Rdf::Builders::SubPropertyOfHandler.new(:sub_property_of))

    register_handler("owl:equivalentProperty", Rdf::Builders::LiteralHandler.new(:equivalent))
  end

  def call(predicate, objects)
    return if IGNORE_PREDICATES.include?(predicate)
    unless super
      puts "unknown property key: #{predicate}"
      Rails.logger.warn("unknown property key: #{predicate}")
    end
    nil
  end
end
