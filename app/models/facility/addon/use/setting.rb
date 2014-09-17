# coding: utf-8
module Facility::Addon::Use
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_use_categories, class_name: "Facility::Node::Category"
      permit_params st_use_category_ids: []
    end

    set_order 510
  end
end
