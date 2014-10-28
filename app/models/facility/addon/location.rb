module Facility::Addon
  module Location
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :locations, class_name: "Facility::Node::Location"
      permit_params location_ids: []
    end

    set_order 320
  end
end
