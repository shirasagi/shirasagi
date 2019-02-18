module Opendata::Addon::Harvest
  module ImporterAreaSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :default_areas, class_name: 'Opendata::Node::Area'
      permit_params default_area_ids: []
    end
  end
end
