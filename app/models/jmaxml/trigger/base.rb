class Jmaxml::Trigger::Base
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  store_in collection: "jmaxml_triggers"

  set_permission_name "cms_tools", :use

  attr_accessor :in_type

  field :name, type: String
  field :training_status, type: String, default: 'disabled'
  field :test_status, type: String, default: 'disabled'
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
      Jmaxml::Trigger::QuakeIntensityFlash,
      Jmaxml::Trigger::QuakeInfo,
      Jmaxml::Trigger::TsunamiAlert,
      Jmaxml::Trigger::TsunamiInfo,
      Jmaxml::Trigger::WeatherAlert,
      Jmaxml::Trigger::LandslideInfo,
      Jmaxml::Trigger::FloodForecast,
      Jmaxml::Trigger::VolcanoFlash,
      Jmaxml::Trigger::AshFallForecast,
      Jmaxml::Trigger::TornadoAlert ]
    sub_classes.map do |v|
      [ v.model_name.human, v.name ]
    end
  end

  def training_status_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def test_status_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def verify(page, context, &block)
    raise NotImplementedError
  end

  private
    def weather_xml_status_enabled?(status)
      case status
      when Jmaxml::Status::NORMAL
        return true
      when Jmaxml::Status::TRAINING
        return training_status == 'enabled'
      when Jmaxml::Status::TEST
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
