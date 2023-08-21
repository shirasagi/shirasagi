module Garbage::Reference
  module Category
    extend ActiveSupport::Concern

    included do
      embeds_ids :categories, class_name: "Garbage::Node::Category"
      permit_params category_ids: []

      embeds_ids :st_categories, class_name: "Garbage::Node::Category"
      permit_params st_category_ids: []
    end
  end
end
