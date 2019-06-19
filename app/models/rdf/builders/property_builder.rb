class Rdf::Builders::PropertyBuilder < Rdf::Builders::BaseBuilder
  include Rdf::Builders::Traversable
  include Rdf::Builders::Context

  IGNORE_PREDICATES = %w(rdf:type
                         dc:hasVersion
                         dc:issued
                         dc:modified
                         http://purl.org/dc/terms/hasVersion
                         http://purl.org/dc/terms/issued
                         http://purl.org/dc/terms/modified
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
    register_handler("dc:description", Rdf::Builders::LangLiteralHandler.new(:comments, overwrites: false))
    alias_handler "http://purl.org/dc/terms/description", "dc:description"
    alias_handler "skos:note", "dc:description"

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
