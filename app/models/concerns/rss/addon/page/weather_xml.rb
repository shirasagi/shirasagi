module Rss::Addon::Page
  module WeatherXml
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :xml, type: String
      permit_params :xml
    end
  end
end
