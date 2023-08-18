class Rdf::Builders::VocabBuilder < Rdf::Builders::BaseBuilder
  include Rdf::Builders::Traversable
  include Rdf::Builders::Context

  IGNORE_PREDICATES = %w(rdf:type dc:source).freeze

  def initialize
    register_handler("cc:license", Rdf::Builders::LiteralHandler.new(:license))
    alias_handler "http://creativecommons.org/ns#license", "cc:license"
    alias_handler "http://purl.org/dc/terms/license", "cc:license"

    register_handler("owl:versionInfo", Rdf::Builders::LiteralHandler.new(:version))
    register_handler("dc:issued", Rdf::Builders::LiteralHandler.new(:published))
    alias_handler "dc:modified", "dc:issued"
    alias_handler "http://purl.org/dc/terms/issued", "dc:issued"
    alias_handler "http://purl.org/dc/terms/modified", "dc:issued"

    register_handler("rdfs:label", Rdf::Builders::LangLiteralHandler.new(:labels))
    alias_handler "dc:title", "rdfs:label"
    alias_handler "http://purl.org/dc/terms/title", "rdfs:label"
    alias_handler "dc11:title", "rdfs:label"
    alias_handler "http://purl.org/dc/elements/1.1/title", "rdfs:label"
    register_handler("rdfs:comment", Rdf::Builders::LangLiteralHandler.new(:comments))
    register_handler("dc:description", Rdf::Builders::LangLiteralHandler.new(:comments, overwrites: false))
    alias_handler "http://purl.org/dc/terms/description", "dc:description"
    alias_handler "dc11:description", "dc:description"
    alias_handler "http://purl.org/dc/elements/1.1/description", "dc:description"

    register_handler("dc:creator", Rdf::Builders::CreatorHandler.new(:creators))
    alias_handler "http://purl.org/dc/terms/creator", "dc:creator"
    alias_handler "dc:publisher", "dc:creator"
    alias_handler "http://purl.org/dc/terms/publisher", "dc:creator"
    alias_handler "dc11:creator", "dc:creator"
    alias_handler "http://purl.org/dc/elements/1.1/creator", "dc:creator"

    register_handler("http://purl.org/vocab/vann/preferredNamespaceUri", Rdf::Builders::PreferredNamespaceUriHandler.new(:uri))
  end

  def call(predicate, objects)
    return if IGNORE_PREDICATES.include?(predicate)
    unless super
      puts "unknown vocab key: #{predicate}"
      # Rails.logger.warn("unknown vocab key: #{predicate}")
    end
    nil
  end
end
