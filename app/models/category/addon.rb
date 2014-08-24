# coding: utf-8
module Category::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 300
  end

  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Category::Node::Base"
      permit_params st_category_ids: []
    end

    set_order 200
  end
end
