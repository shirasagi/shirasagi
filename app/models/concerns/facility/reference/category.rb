module Facility::Reference
  module Category
    extend ActiveSupport::Concern

    included do
      embeds_ids :categories, class_name: "Facility::Node::Category"
      embeds_ids :st_categories, class_name: "Facility::Node::Category"
      permit_params category_ids: [], st_category_ids: []
    end
  end
end
