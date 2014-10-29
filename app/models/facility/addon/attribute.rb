module Facility::Addon
  module Attribute
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :attributes, class_name: "Facility::Node::Attribute"
      permit_params attribute_ids: []
    end

    set_order 310
  end
end
