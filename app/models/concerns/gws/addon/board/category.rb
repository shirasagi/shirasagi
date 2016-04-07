module Gws::Addon::Board::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Board::Category"
    permit_params category_ids: []
  end
end
