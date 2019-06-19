module Gws::Addon::Survey::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: 'Gws::Survey::Category'
    permit_params category_ids: []
  end
end
