module Gws::Addon::Report::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: 'Gws::Report::Category'
    permit_params category_ids: []
  end
end
