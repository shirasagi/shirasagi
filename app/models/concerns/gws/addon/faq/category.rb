module Gws::Addon::Faq::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Faq::Category"
    permit_params category_ids: []
  end
end
