module Gws::Addon::Questionnaire::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: 'Gws::Questionnaire::Category'
    permit_params category_ids: []
  end
end
