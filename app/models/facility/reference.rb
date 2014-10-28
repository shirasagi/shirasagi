module Facility::Reference
  module Category
    extend ActiveSupport::Concern

    included do
      embeds_ids :categories, class_name: "Facility::Node::Category"
      permit_params category_ids: []

      embeds_ids :st_categories, class_name: "Facility::Node::Category"
      permit_params st_category_ids: []
    end
  end

  module Location
    extend ActiveSupport::Concern

    included do
      embeds_ids :locations, class_name: "Facility::Node::Location"
      permit_params location_ids: []

      embeds_ids :st_locations, class_name: "Facility::Node::Location"
      permit_params st_location_ids: []
    end
  end

  module Feature
    extend ActiveSupport::Concern

    included do
      embeds_ids :features, class_name: "Facility::Node::Feature"
      permit_params feature_ids: []

      embeds_ids :st_features, class_name: "Facility::Node::Feature"
      permit_params st_feature_ids: []
    end
  end
end
