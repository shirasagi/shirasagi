class Rdf::Builders::VocabBuilder < Rdf::Builders::BaseBuilder
  include Rdf::Builders::Traversable
  include Rdf::Builders::Context

  IGNORE_PREDICATES = %w(rdf:type).freeze

  def initialize
    register_handler("cc:license", Rdf::Builders::LiteralHandler.new(:license))
    register_handler("owl:versionInfo", Rdf::Builders::LiteralHandler.new(:version))
    register_handler("dc:issued", Rdf::Builders::LiteralHandler.new(:published))
    alias_handler "dc:modified", "dc:issued"

    register_handler("rdfs:label", Rdf::Builders::LangLiteralHandler.new(:labels))
    register_handler("rdfs:comment", Rdf::Builders::LangLiteralHandler.new(:comments))
    alias_handler "dc:title", "rdfs:label"

    register_handler("dc:creator", Rdf::Builders::CreatorHandler.new(:creators))
    alias_handler "dc:publisher", "dc:creator"
    alias_handler "dc11:creator", "dc:creator"

    register_handler("http://purl.org/vocab/vann/preferredNamespaceUri", Rdf::Builders::PreferredNamespaceUriHandler.new(:uri))
  end

  def call(predicate, objects)
    return if IGNORE_PREDICATES.include?(predicate)
    unless super
      puts "unknown vocab key: #{predicate}"
      Rails.logger.warn("unknown vocab key: #{predicate}")
    end
    nil
  end
end
