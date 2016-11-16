class Rss::WeatherXml::Trigger::Base
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  store_in collection: "rss_weather_xml_triggers"

  set_permission_name "cms_tools", :use

  attr_accessor :in_type

  field :name, type: String
  field :training_status, type: String
  field :test_status, type: String
  validates :name, presence: true, length: { maximum: 40 }
  validates :training_status, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }
  validates :test_status, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }
  permit_params :in_type, :name, :training_status, :test_status

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
      Rss::WeatherXml::Trigger::QuakeInfo,
      Rss::WeatherXml::Trigger::TsunamiAlert,
      Rss::WeatherXml::Trigger::TsunamiInfo,
      Rss::WeatherXml::Trigger::WeatherAlert,
      Rss::WeatherXml::Trigger::LandslideInfo,
      Rss::WeatherXml::Trigger::FloodForecast,
      Rss::WeatherXml::Trigger::VolcanoFlash ]
    sub_classes.map do |v|
      [ v.model_name.human, v.name ]
    end
  end

  def training_status_options
    %w(disabled enabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end

  def test_status_options
    %w(disabled enabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end

  def verify(page, context, &block)
    raise NotImplementedError
  end

  private
    def weather_xml_status_enabled?(status)
      case status
      when Rss::WeatherXml::Status::NORMAL
        return true
      when Rss::WeatherXml::Status::TRAINING
        return training_status == 'enabled'
      when Rss::WeatherXml::Status::TEST
        return test_status == 'enabled'
      end
    end

    def fresh_xml?(page, context)
      report_datetime = REXML::XPath.first(context.xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip
      if report_datetime.present?
        report_datetime = Time.zone.parse(report_datetime) rescue nil
      end
      return if report_datetime.blank?

      diff = Time.zone.now - report_datetime
      diff.abs <= 1.hour
    end
end
