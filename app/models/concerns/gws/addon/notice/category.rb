module Gws::Addon::Notice::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Notice::Category"
    permit_params category_ids: []
  end
end
