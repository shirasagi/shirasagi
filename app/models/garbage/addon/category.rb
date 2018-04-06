module Garbage::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :categories, class_name: "Garbage::Node::Category"
      permit_params category_ids: []
    end
  end
end
