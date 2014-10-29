module Event::Addon::Category
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Category::Node::Base"
      permit_params st_category_ids: []
    end

    set_order 500
  end
end
