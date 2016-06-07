module Member::Addon::Photo
  module Category
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :photo_categories, class_name: "Member::Node::PhotoCategory"
      permit_params photo_category_ids: []
    end
  end
end
