class Rdf::Builders::PropertyBuidler < Rdf::Builders::BaseBuilder
  include Rdf::Builders::Traversable
  include Rdf::Builders::Context

  IGNORE_PREDICATES = %w(rdf:type
                         dc:hasVersion
                         dc:issued
                         dc:modified
                         rdfs:isDefinedBy
                         rdfs:subPropertyOf
                         schema:domainIncludes
                         vs:term_status
                         prov:wasDerivedFrom
                         owl:equivalentProperty
                         owl:inverseOf).freeze

  def initialize
    register_handler("rdfs:label", Rdf::Builders::LangLiteralHandler.new(:labels))

    register_handler("rdfs:comment", Rdf::Builders::LangLiteralHandler.new(:comments))
    alias_handler "dc:description", "rdfs:comment"
    alias_handler "skos:note", "rdfs:comment"

    register_handler("rdfs:domain", Rdf::Builders::RangeHandler.new(:domains))

    register_handler("rdfs:range", Rdf::Builders::RangeHandler.new(:ranges))
  end

  def call(predicate, objects)
    return if IGNORE_PREDICATES.include?(predicate)
    unless super
      Rails.logger.debug "unknown property key: #{predicate}"
    end
    nil
  end
end
