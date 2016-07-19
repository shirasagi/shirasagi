class Rss::Agents::Nodes::WeatherXmlController < ApplicationController
  include Cms::NodeFilter::View
  include Rss::Public::PubSubHubbubFilter
  helper Cms::ListHelper

  model Rss::WeatherXmlPage
  set_job_model Rss::ImportWeatherXmlJob

  private
    def protect_csrf?
      false
    end
end
