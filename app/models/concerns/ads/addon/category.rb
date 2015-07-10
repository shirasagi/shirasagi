module Ads::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :ads_categories, class_name: "Cms::Node"

      permit_params ads_category_ids: []
    end
  end
end
