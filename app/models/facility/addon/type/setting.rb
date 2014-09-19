# coding: utf-8
module Facility::Addon::Type
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_type_categories, class_name: "Facility::Node::Category"
      permit_params st_type_category_ids: []
    end

    set_order 500
  end
end
