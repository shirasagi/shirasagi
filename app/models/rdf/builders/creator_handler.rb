class Rdf::Builders::CreatorHandler < Rdf::Builders::BaseHandler
  def initialize(key)
    @key = key
  end

  def call(predicate, objects)
    sub_attributes = {}
    objects.each do |object|
      if object.node?
        @context.traverse(object).each do |sub_statement|
          case sub_statement.predicate.pname
          when "foaf:name" then
            sub_attributes[:names] = {} unless sub_attributes.key?(:names)
            lang = sub_statement.object.language
            lang ||= :invariant
            value = sub_statement.object.object
            sub_attributes[:names][lang] = value
          when "foaf:homepage" then
            sub_attributes[:homepage] = sub_statement.object.to_s
          end
        end
      elsif object.literal?
        sub_attributes = { names: { invariant: object.value } }
      elsif object.uri?
        sub_attributes = { homepage: object.to_s }
      end
    end
    @context.attributes[@key] = [] unless @context.attributes.key?(@key)
    @context.attributes[@key] << sub_attributes if sub_attributes.present?
  end
end
