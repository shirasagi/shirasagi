class Rss::WeatherXml::Action::PublishPagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rss::WeatherXml::Action::PublishPage
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      redirect_to rss_weather_xml_action_bases_path
    end
end
