class Rdf::Builders::PreferredNamespaceUriHandler < Rdf::Builders::BaseHandler
  def initialize(key)
    @key = key
  end

  def call(predicate, objects)
    @context.attributes[@key] = objects.first.to_s
  end
end
