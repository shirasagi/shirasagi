module Gws::Addon::Qna::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: "Gws::Qna::Category"
    permit_params category_ids: []
  end
end
