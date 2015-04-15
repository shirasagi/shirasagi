class Rdf::Class
  extend SS::Translation
  include SS::Document
  include Rdf::Object
  include Opendata::Addon::Category

  belongs_to :sub_class, class_name: "Rdf::Class"

  permit_params :sub_class_id

  def properties
    Rdf::Prop.in(class_ids: [_id])
  end

  def expander
    # expand_properties and flattern_properties is too slow.
    # we need we Rdf::PropertyExpander instance becase to improve performace using some caches.
    @expander ||= Rdf::PropertyExpander.new
  end

  def expand_properties(check = {})
    expander.expand(self)
  end

  def flattern_properties
    expander.flattern(self)
  end
end
