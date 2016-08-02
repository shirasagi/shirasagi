class Rdf::Builders::SubClassOfHandler < Rdf::Builders::BaseHandler
  def call(_, objects)
    sub_class_object = objects.find { |object| object.uri? }
    properties = create_class_properties(objects)
    @context.attributes[:sub_class_of] = sub_class_object.to_s if sub_class_object.present?
    @context.attributes[:properties] = properties if properties.present?
  end

  private
    def select_restriction_nodes(objects)
      nodes = objects.select do |object|
        object.node?
      end
      nodes = nodes.map do |object|
        @context.convert_to_hash(object)
      end
      nodes.select do |sub_hash|
        sub_hash["rdf:type"].first.pname == "owl:Restriction"
      end
    end

    def create_class_properties(objects)
      properties = select_restriction_nodes(objects).map do |sub_hash|
        property = {}

        sub_hash.each do |key, value|
          case key
          when "rdf:type" then
            # ignore
          when "owl:onProperty" then
            property[:property] = value.first.to_s
          when "owl:allValuesFrom", "owl:onDataRange", "owl:onClass" then
            if property.key?(:datatype)
              puts "[warning] duplicate key #{key} for :datatype"
              Rails.logger.warn("duplicate key #{key} for :datatype")
            else
              property[:datatype] = value.first.to_s
            end
          when "owl:qualifiedCardinality", "owl:cardinality" then
            property[:cardinality] = value.first.value.to_s
          when "owl:maxQualifiedCardinality", "owl:maxCardinality" then
            property[:cardinality] = "0..#{value.first.value}"
          when "owl:minQualifiedCardinality", "owl:minCardinality" then
            property[:cardinality] = "#{value.first.value}..n"
          # when "owl:equivalentClass" then
          #   equivalent = convert_to_hash(object)["owl:onDatatype"].first
          #   property[:equivalent] = equivalent.to_s
          when "rdfs:comment" then
            property[:comments] = {}
            value.each do |object|
              lang = object.language
              lang ||= :invariant
              value = object.object
              property[:comments][lang] = value
            end
          else
            puts "unknown class property key: #{keyy}"
            Rails.logger.warn("unknown class propert key: #{key}")
          end
        end
        property
      end
      properties.to_a
    end
end
