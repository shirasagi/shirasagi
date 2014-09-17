# coding: utf-8
module Facility::Addon::Location
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :location_categories, class_name: "Facility::Node::Category"
      permit_params location_category_ids: []
    end

    set_order 320
  end
end
