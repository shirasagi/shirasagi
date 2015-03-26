class Rdf::Class
  extend SS::Translation
  include SS::Document
  include Rdf::Object

  field :sub_class_of, type: String
  field :properties, type: Array

  permit_params :sub_class_of, :properties
  permit_params properties: ["property", "class", "cardinality", "comments", {comments: ["ja", "en", "invariant"]}]
end
