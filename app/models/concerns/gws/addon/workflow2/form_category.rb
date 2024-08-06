module Gws::Addon::Workflow2::FormCategory
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Workflow2::Form::Category"
    permit_params category_ids: []
  end
end
