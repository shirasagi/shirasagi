module Gws::Addon::Circular::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: 'Gws::Circular::Category'
    permit_params category_ids: []
  end
end
