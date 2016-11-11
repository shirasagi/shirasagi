class Rss::WeatherXml::Trigger::Base
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  store_in collection: "rss_weather_xml_triggers"

  set_permission_name "cms_tools", :use

  attr_accessor :in_type

  field :name, type: String
  field :training_state, type: String
  validates :name, presence: true, length: { maximum: 40 }
  validates :training_state, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }
  permit_params :in_type, :name, :training_state

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end

  def type_options
    sub_classes = [
      Rss::WeatherXml::Trigger::QuakeIntensityFlash,
      Rss::WeatherXml::Trigger::TsunamiAlert,
      Rss::WeatherXml::Trigger::WeatherAlert,
      Rss::WeatherXml::Trigger::LandslideInfo,
      Rss::WeatherXml::Trigger::FloodForecast ]
    sub_classes.map do |v|
      [ v.model_name.human, v.name ]
    end
  end

  def training_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end
end
