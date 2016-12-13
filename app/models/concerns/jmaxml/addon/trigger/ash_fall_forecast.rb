module Jmaxml::Addon::Trigger::AshFallForecast
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :sub_types, type: SS::Extensions::Words
    embeds_ids :target_regions, class_name: "Jmaxml::ForecastRegion"
    permit_params sub_types: [], target_region_ids: []
  end
end
