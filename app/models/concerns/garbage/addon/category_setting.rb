module Garbage::Addon
  module CategorySetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Garbage::Node::Category"
      permit_params st_category_ids: []
    end
  end
end
