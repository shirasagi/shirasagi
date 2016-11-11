class Rss::WeatherXml::Trigger::QuakeIntensityFlash < Rss::WeatherXml::Trigger::Base
  field :earthquake_intensity, type: String, default: '5+'
  embeds_ids :target_regions, class_name: "Rss::WeatherXml::QuakeRegion"
  permit_params :earthquake_intensity
  permit_params target_region_ids: []
  validates :earthquake_intensity, inclusion: { in: %w(0 1 2 3 4 5- 5+ 6- 6+ 7) }

  def earthquake_intensity_options
    %w(4 5- 5+ 6- 6+ 7).map { |value| [I18n.t("rss.options.earthquake_intensity.#{value}"), value] }
  end
end
