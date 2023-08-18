module Jmaxml::Addon::Trigger::FloodForecast
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :target_regions, class_name: "Jmaxml::WaterLevelStation"
    permit_params target_region_ids: []
  end
end
