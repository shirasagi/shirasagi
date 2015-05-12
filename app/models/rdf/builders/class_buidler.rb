class Rdf::Builders::ClassBuidler < Rdf::Builders::BaseBuilder
  include Rdf::Builders::Traversable
  include Rdf::Builders::Context

  IGNORE_PREDICATES = %w(rdf:type
                         rdfs:isDefinedBy
                         rdfs:seeAlso
                         dc:hasVersion
                         dc:issued
                         dc:modified
                         vs:term_status
                         owl:disjointWith
                         owl:equivalentClass
                         prov:wasDerivedFrom).freeze

  def initialize
    register_handler("rdfs:label", Rdf::Builders::LangLiteralHandler.new(:labels))

    register_handler("rdfs:comment", Rdf::Builders::LangLiteralHandler.new(:comments))
    alias_handler "dc:description", "rdfs:comment"

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
