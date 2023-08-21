module Gws::Addon::Share::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Share::Category"
    permit_params category_ids: []
  end
end
