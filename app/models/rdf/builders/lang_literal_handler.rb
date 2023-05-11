class Rdf::Builders::LangLiteralHandler < Rdf::Builders::BaseHandler
  def initialize(key, options = {})
    @key = key
    @options = options
  end

  def call(predicate, objects)
    objects.each do |object|
      if object.literal?
        lang = object.language
        lang ||= :invariant
        value = object.object
        @context.attributes[@key] = {}.with_indifferent_access unless @context.attributes.key?(@key)
        if overwrite? || @context.attributes[@key][lang].blank?
          @context.attributes[@key][lang] = value
        end
      elsif object.uri?
        if overwrite? || @context.attributes[@key].blank?
          @context.attributes[@key] = object.to_s
        end
      end
    end
  end

  private

  def overwrite?
    return true if !@options.key?(:overwrites)
    @options[:overwrites]
  end
end
