module Facility::Addon
  module CategorySetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Facility::Node::Category"
      permit_params st_category_ids: []
    end

    set_order 500
  end
end
