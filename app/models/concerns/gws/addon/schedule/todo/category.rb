module Gws::Addon::Schedule::Todo::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Schedule::TodoCategory"
    permit_params category_ids: []
  end
end
