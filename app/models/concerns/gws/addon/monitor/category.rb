module Gws::Addon::Monitor::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Monitor::Category"
    permit_params category_ids: []
  end
end

