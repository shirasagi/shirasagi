module Cms::Addon::OpendataRef::Category
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :opendata_categories, class_name: "Opendata::Node::Category", metadata: { on_copy: :clear }
    permit_params opendata_category_ids: []
  end
end
