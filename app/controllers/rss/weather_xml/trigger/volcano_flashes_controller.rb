class Rss::WeatherXml::Trigger::VolcanoFlashesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rss::WeatherXml::Trigger::VolcanoFlash
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
