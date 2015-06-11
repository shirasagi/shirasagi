module Facility::Reference
  module Location
    extend ActiveSupport::Concern

    included do
      embeds_ids :locations, class_name: "Facility::Node::Location"
      embeds_ids :st_locations, class_name: "Facility::Node::Location"
      permit_params location_ids: [], st_location_ids: []
    end
  end
end
