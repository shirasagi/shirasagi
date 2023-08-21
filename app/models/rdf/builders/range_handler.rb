class Rdf::Builders::RangeHandler < Rdf::Builders::BaseHandler
  def initialize(key)
    @key = key
  end

  def call(predicate, objects)
    objects.each do |object|
      if object.literal?
        @context.attributes[@key] = [] unless @context.attributes.key?(@key)
        @context.attributes[@key] << object.value
      elsif object.uri?
        @context.attributes[@key] = [] unless @context.attributes.key?(@key)
        @context.attributes[@key] << object.to_s
      end
    end
  end
end
