# coding: utf-8
module Facility::Reference
  module Location
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_location_categories, class_name: "Facility::Node::Category"
      permit_params st_location_category_ids: []
    end
  end

  module Type
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_type_categories, class_name: "Facility::Node::Category"
      permit_params st_location_category_ids: []
    end
  end

  module Use
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_use_categories, class_name: "Facility::Node::Category"
      permit_params st_location_category_ids: []
    end
  end
end
