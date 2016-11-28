module Jmaxml::Addon::Trigger::TornadoAlert
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :target_regions, class_name: "Jmaxml::ForecastRegion"
    permit_params target_region_ids: []
  end
end
