# coding: utf-8
module Facility::Addon::Location
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_locations, class_name: "Facility::Node::Location"
      permit_params st_location_ids: []
    end

    set_order 520
  end
end
