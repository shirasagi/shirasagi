class Rdf::Builders::LiteralHandler < Rdf::Builders::BaseHandler
  def initialize(key)
    @key = key
  end

  def call(predicate, objects)
    object = objects.first
    if object.literal?
      @context.attributes[@key] = object.value
    elsif object.uri?
      @context.attributes[@key] = object.to_s
    end
  end
end
