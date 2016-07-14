class Rss::WeatherXmlsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Rss::PubSubHubbubFilter

  model Rss::WeatherXmlPage
end
