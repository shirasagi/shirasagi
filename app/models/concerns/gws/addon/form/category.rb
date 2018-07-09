module Gws::Addon::Form::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: 'Gws::Form::Category'
    permit_params category_ids: []
  end
end
