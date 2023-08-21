module Chat::Addon::Category
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :categories, class_name: 'Chat::Category'
    permit_params category_ids: []
  end
end
