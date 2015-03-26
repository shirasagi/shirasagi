class Rdf::Builders::LangLiteralHandler < Rdf::Builders::BaseHandler
  def initialize(key)
    @key = key
  end

  def call(predicate, objects)
    object = objects.first
    if object.literal?
      lang = object.language
      lang ||= :invariant
      value = object.object
      @context.attributes[@key] = {} unless @context.attributes.key?(@key)
      @context.attributes[@key][lang] = value
    elsif object.uri?
      @context.attributes[@key] = object.to_s
    end
  end
end
