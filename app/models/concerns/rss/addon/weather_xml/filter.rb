module Rss::Addon::WeatherXml::Filter
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_many :filters, class_name: "Rss::WeatherXml::Filter"
  end
end
