# coding: utf-8
module Facility::Addon::Type
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :type_categories, class_name: "Facility::Node::Category"
      permit_params type_category_ids: []
    end

    set_order 300
  end
end
