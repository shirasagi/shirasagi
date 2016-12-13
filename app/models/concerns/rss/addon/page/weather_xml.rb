module Rss::Addon::Page
  module WeatherXml
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :event_id, type: String
      field :xml, type: String
      permit_params :event_id, :xml
    end
  end
end
