class Rss::WeatherXml::Trigger::TornadoAlertsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rss::WeatherXml::Trigger::TornadoAlert
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      redirect_to rss_weather_xml_trigger_bases_path
    end
end
