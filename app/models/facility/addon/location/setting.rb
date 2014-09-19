# coding: utf-8
module Facility::Addon::Location
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_location_categories, class_name: "Facility::Node::Category"
      permit_params st_location_category_ids: []
    end

    set_order 520
  end
end
