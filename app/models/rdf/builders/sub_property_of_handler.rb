class Rdf::Builders::SubPropertyOfHandler < Rdf::Builders::BaseHandler
  def initialize(key)
    @key = key
  end

  def call(predicate, objects)
    @context.attributes[@key] = [] if @context.attributes[@key].blank?
    objects.each do |object|
      if object.literal?
        @context.attributes[@key] << object.value
      elsif object.uri?
        @context.attributes[@key] << object.to_s
      end
    end
  end
end
