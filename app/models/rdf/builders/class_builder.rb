class Rdf::Builders::ClassBuilder < Rdf::Builders::BaseBuilder
  include Rdf::Builders::Traversable
  include Rdf::Builders::Context

  IGNORE_PREDICATES = %w(rdf:type
                         rdfs:isDefinedBy
                         rdfs:seeAlso
                         dc:hasVersion
                         dc:issued
                         dc:modified
                         http://purl.org/dc/terms/hasVersion
                         http://purl.org/dc/terms/issued
                         http://purl.org/dc/terms/modified
                         vs:term_status
                         owl:disjointWith
                         owl:equivalentClass
                         prov:wasDerivedFrom).freeze

  def initialize
    register_handler("rdfs:label", Rdf::Builders::LangLiteralHandler.new(:labels))

    register_handler("rdfs:comment", Rdf::Builders::LangLiteralHandler.new(:comments))
    register_handler("dc:description", Rdf::Builders::LangLiteralHandler.new(:comments, overwrites: false))
    alias_handler "http://purl.org/dc/terms/description", "dc:description"

    register_handler("rdfs:subClassOf", Rdf::Builders::SubClassOfHandler.new)
  end

  def call(predicate, objects)
    return if IGNORE_PREDICATES.include?(predicate)
    unless super
      Rails.logger.debug "unknown class key: #{predicate}"
    end
    nil
  end
end
