class Rdf::Prop
  extend SS::Translation
  include SS::Document
  include Rdf::Object

  belongs_to :range, class_name: "Rdf::Class"
  embeds_ids :classes, class_name: "Rdf::Class"

  permit_params :range_id, :sub_property_id, :cardinality, :class_ids
  permit_params class_ids: []

  scope :rdf_class, ->(rdf_class) { self.in(class_ids: [rdf_class.id]) }
end
