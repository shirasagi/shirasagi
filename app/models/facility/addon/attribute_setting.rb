module Facility::Addon
  module AttributeSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_attributes, class_name: "Facility::Node::Attribute"
      permit_params st_attribute_ids: []
    end

    set_order 510
  end
end
