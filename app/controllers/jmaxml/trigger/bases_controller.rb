class Jmaxml::Trigger::BasesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Jmaxml::Trigger::Base
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def show
      raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Jmaxml::Trigger::QuakeIntensityFlash'
        redirect_to jmaxml_trigger_quake_intensity_flash_path
      when 'Jmaxml::Trigger::QuakeInfo'
        redirect_to jmaxml_trigger_quake_info_path
      when 'Jmaxml::Trigger::TsunamiAlert'
        redirect_to jmaxml_trigger_tsunami_alert_path
      when 'Jmaxml::Trigger::TsunamiInfo'
        redirect_to jmaxml_trigger_tsunami_info_path
      when 'Jmaxml::Trigger::WeatherAlert'
        redirect_to jmaxml_trigger_weather_alert_path
      when 'Jmaxml::Trigger::LandslideInfo'
        redirect_to jmaxml_trigger_landslide_info_path
      when 'Jmaxml::Trigger::FloodForecast'
        redirect_to jmaxml_trigger_flood_forecast_path
      when 'Jmaxml::Trigger::VolcanoFlash'
        redirect_to jmaxml_trigger_volcano_flash_path
      when 'Jmaxml::Trigger::AshFallForecast'
        redirect_to jmaxml_trigger_ash_fall_forecast_path
      when 'Jmaxml::Trigger::TornadoAlert'
        redirect_to jmaxml_trigger_tornado_alert_path
      else
        raise "400"
      end
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render file: :choice
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.in_type
      when 'Jmaxml::Trigger::QuakeIntensityFlash'
        redirect_to new_jmaxml_trigger_quake_intensity_flash_path
      when 'Jmaxml::Trigger::QuakeInfo'
        redirect_to new_jmaxml_trigger_quake_info_path
      when 'Jmaxml::Trigger::TsunamiAlert'
        redirect_to new_jmaxml_trigger_tsunami_alert_path
      when 'Jmaxml::Trigger::TsunamiInfo'
        redirect_to new_jmaxml_trigger_tsunami_info_path
      when 'Jmaxml::Trigger::WeatherAlert'
        redirect_to new_jmaxml_trigger_weather_alert_path
      when 'Jmaxml::Trigger::LandslideInfo'
        redirect_to new_jmaxml_trigger_landslide_info_path
      when 'Jmaxml::Trigger::FloodForecast'
        redirect_to new_jmaxml_trigger_flood_forecast_path
      when 'Jmaxml::Trigger::VolcanoFlash'
        redirect_to new_jmaxml_trigger_volcano_flash_path
      when 'Jmaxml::Trigger::AshFallForecast'
        redirect_to new_jmaxml_trigger_ash_fall_forecast_path
      when 'Jmaxml::Trigger::TornadoAlert'
        redirect_to new_jmaxml_trigger_tornado_alert_path
      else
        raise "400"
      end
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Jmaxml::Trigger::QuakeIntensityFlash'
        redirect_to edit_jmaxml_trigger_quake_intensity_flash_path
      when 'Jmaxml::Trigger::QuakeInfo'
        redirect_to edit_jmaxml_trigger_quake_info_path
      when 'Jmaxml::Trigger::TsunamiAlert'
        redirect_to edit_jmaxml_trigger_tsunami_alert_path
      when 'Jmaxml::Trigger::TsunamiInfo'
        redirect_to edit_jmaxml_trigger_tsunami_info_path
      when 'Jmaxml::Trigger::WeatherAlert'
        redirect_to edit_jmaxml_trigger_weather_alert_path
      when 'Jmaxml::Trigger::LandslideInfo'
        redirect_to edit_jmaxml_trigger_landslide_info_path
      when 'Jmaxml::Trigger::FloodForecast'
        redirect_to edit_jmaxml_trigger_flood_forecast_path
      when 'Jmaxml::Trigger::VolcanoFlash'
        redirect_to edit_jmaxml_trigger_volcano_flash_path
      when 'Jmaxml::Trigger::AshFallForecast'
        redirect_to edit_jmaxml_trigger_ash_fall_forecast_path
      when 'Jmaxml::Trigger::TornadoAlert'
        redirect_to edit_jmaxml_trigger_tornado_alert_path
      else
        raise "400"
      end
    end

    def delete
      raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Jmaxml::Trigger::QuakeIntensityFlash'
        redirect_to delete_jmaxml_trigger_quake_intensity_flash_path
      when 'Jmaxml::Trigger::QuakeInfo'
        redirect_to delete_jmaxml_trigger_quake_info_path
      when 'Jmaxml::Trigger::TsunamiAlert'
        redirect_to delete_jmaxml_trigger_tsunami_alert_path
      when 'Jmaxml::Trigger::TsunamiInfo'
        redirect_to delete_jmaxml_trigger_tsunami_info_path
      when 'Jmaxml::Trigger::WeatherAlert'
        redirect_to delete_jmaxml_trigger_weather_alert_path
      when 'Jmaxml::Trigger::LandslideInfo'
        redirect_to delete_jmaxml_trigger_landslide_info_path
      when 'Jmaxml::Trigger::FloodForecast'
        redirect_to delete_jmaxml_trigger_flood_forecast_path
      when 'Jmaxml::Trigger::VolcanoFlash'
        redirect_to delete_jmaxml_trigger_volcano_flash_path
      when 'Jmaxml::Trigger::AshFallForecast'
        redirect_to delete_jmaxml_trigger_ash_fall_forecast_path
      when 'Jmaxml::Trigger::TornadoAlert'
        redirect_to delete_jmaxml_trigger_tornado_alert_path
      else
        raise "400"
      end
    end
end
