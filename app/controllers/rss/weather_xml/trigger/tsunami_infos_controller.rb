class Rss::WeatherXml::Trigger::TsunamiInfosController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rss::WeatherXml::Trigger::TsunamiInfo
  navi_view "rss/main/navi"
  append_view_path "app/views/rss/weather_xml/trigger/tsunami_main"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      redirect_to rss_weather_xml_trigger_bases_path
    end
end
