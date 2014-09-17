# coding: utf-8
module Facility::Addon::Use
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :use_categories, class_name: "Facility::Node::Category"
      permit_params use_category_ids: []
    end

    set_order 310
  end
end
