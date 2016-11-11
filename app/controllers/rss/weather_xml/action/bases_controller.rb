class Rss::WeatherXml::Action::BasesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rss::WeatherXml::Action::Base
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def show
      raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
        when 'Rss::WeatherXml::Action::PublishPage'
          redirect_to rss_weather_xml_action_publish_page_path
        when 'Rss::WeatherXml::Action::ChangeUrgency'
          redirect_to rss_weather_xml_action_change_urgency_path
        when 'Rss::WeatherXml::Action::SendMail'
          redirect_to rss_weather_xml_action_send_mail_path
        else
          raise "400"
      end
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.in_type
        when 'Rss::WeatherXml::Action::PublishPage'
          redirect_to new_rss_weather_xml_action_publish_page_path
        when 'Rss::WeatherXml::Action::ChangeUrgency'
          redirect_to new_rss_weather_xml_action_change_urgency_path
        when 'Rss::WeatherXml::Action::SendMail'
          redirect_to new_rss_weather_xml_action_send_mail_path
        else
          raise "400"
      end
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
        when 'Rss::WeatherXml::Action::PublishPage'
          redirect_to edit_rss_weather_xml_action_publish_page_path
        when 'Rss::WeatherXml::Action::ChangeUrgency'
          redirect_to edit_rss_weather_xml_action_change_urgency_path
        when 'Rss::WeatherXml::Action::SendMail'
          redirect_to edit_rss_weather_xml_action_send_mail_path
        else
          raise "400"
      end
    end

    def delete
      raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
        when 'Rss::WeatherXml::Action::PublishPage'
          redirect_to delete_rss_weather_xml_action_publish_page_path
        when 'Rss::WeatherXml::Action::ChangeUrgency'
          redirect_to delete_rss_weather_xml_action_change_urgency_path
        when 'Rss::WeatherXml::Action::SendMail'
          redirect_to delete_rss_weather_xml_action_send_mail_path
        else
          raise "400"
      end
    end
end
