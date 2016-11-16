class Rss::WeatherXml::Trigger::BasesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rss::WeatherXml::Trigger::Base
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def show
      raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Rss::WeatherXml::Trigger::QuakeIntensityFlash'
        redirect_to rss_weather_xml_trigger_quake_intensity_flash_path
      when 'Rss::WeatherXml::Trigger::QuakeInfo'
        redirect_to rss_weather_xml_trigger_quake_info_path
      when 'Rss::WeatherXml::Trigger::TsunamiAlert'
        redirect_to rss_weather_xml_trigger_tsunami_alert_path
      when 'Rss::WeatherXml::Trigger::TsunamiInfo'
        redirect_to rss_weather_xml_trigger_tsunami_info_path
      when 'Rss::WeatherXml::Trigger::WeatherAlert'
        redirect_to rss_weather_xml_trigger_weather_alert_path
      when 'Rss::WeatherXml::Trigger::LandslideInfo'
        redirect_to rss_weather_xml_trigger_landslide_info_path
      when 'Rss::WeatherXml::Trigger::FloodForecast'
        redirect_to rss_weather_xml_trigger_flood_forecast_path
      when 'Rss::WeatherXml::Trigger::VolcanoFlash'
        redirect_to rss_weather_xml_trigger_volcano_flash_path
      else
        raise "400"
      end
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.in_type
      when 'Rss::WeatherXml::Trigger::QuakeIntensityFlash'
        redirect_to new_rss_weather_xml_trigger_quake_intensity_flash_path
      when 'Rss::WeatherXml::Trigger::QuakeInfo'
        redirect_to new_rss_weather_xml_trigger_quake_info_path
      when 'Rss::WeatherXml::Trigger::TsunamiAlert'
        redirect_to new_rss_weather_xml_trigger_tsunami_alert_path
      when 'Rss::WeatherXml::Trigger::TsunamiInfo'
        redirect_to new_rss_weather_xml_trigger_tsunami_info_path
      when 'Rss::WeatherXml::Trigger::WeatherAlert'
        redirect_to new_rss_weather_xml_trigger_weather_alert_path
      when 'Rss::WeatherXml::Trigger::LandslideInfo'
        redirect_to new_rss_weather_xml_trigger_landslide_info_path
      when 'Rss::WeatherXml::Trigger::FloodForecast'
        redirect_to new_rss_weather_xml_trigger_flood_forecast_path
      when 'Rss::WeatherXml::Trigger::VolcanoFlash'
        redirect_to new_rss_weather_xml_trigger_volcano_flash_path
      else
        raise "400"
      end
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Rss::WeatherXml::Trigger::QuakeIntensityFlash'
        redirect_to edit_rss_weather_xml_trigger_quake_intensity_flash_path
      when 'Rss::WeatherXml::Trigger::QuakeInfo'
        redirect_to edit_rss_weather_xml_trigger_quake_info_path
      when 'Rss::WeatherXml::Trigger::TsunamiAlert'
        redirect_to edit_rss_weather_xml_trigger_tsunami_alert_path
      when 'Rss::WeatherXml::Trigger::TsunamiInfo'
        redirect_to edit_rss_weather_xml_trigger_tsunami_info_path
      when 'Rss::WeatherXml::Trigger::WeatherAlert'
        redirect_to edit_rss_weather_xml_trigger_weather_alert_path
      when 'Rss::WeatherXml::Trigger::LandslideInfo'
        redirect_to edit_rss_weather_xml_trigger_landslide_info_path
      when 'Rss::WeatherXml::Trigger::FloodForecast'
        redirect_to edit_rss_weather_xml_trigger_flood_forecast_path
      when 'Rss::WeatherXml::Trigger::VolcanoFlash'
        redirect_to edit_rss_weather_xml_trigger_volcano_flash_path
      else
        raise "400"
      end
    end

    def delete
      raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Rss::WeatherXml::Trigger::QuakeIntensityFlash'
        redirect_to delete_rss_weather_xml_trigger_quake_intensity_flash_path
      when 'Rss::WeatherXml::Trigger::QuakeInfo'
        redirect_to delete_rss_weather_xml_trigger_quake_info_path
      when 'Rss::WeatherXml::Trigger::TsunamiAlert'
        redirect_to delete_rss_weather_xml_trigger_tsunami_alert_path
      when 'Rss::WeatherXml::Trigger::TsunamiInfo'
        redirect_to delete_rss_weather_xml_trigger_tsunami_info_path
      when 'Rss::WeatherXml::Trigger::WeatherAlert'
        redirect_to delete_rss_weather_xml_trigger_weather_alert_path
      when 'Rss::WeatherXml::Trigger::LandslideInfo'
        redirect_to delete_rss_weather_xml_trigger_landslide_info_path
      when 'Rss::WeatherXml::Trigger::FloodForecast'
        redirect_to delete_rss_weather_xml_trigger_flood_forecast_path
      when 'Rss::WeatherXml::Trigger::VolcanoFlash'
        redirect_to delete_rss_weather_xml_trigger_volcano_flash_path
      else
        raise "400"
      end
    end
end
