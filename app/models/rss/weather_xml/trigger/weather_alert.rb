class Rss::WeatherXml::Trigger::WeatherAlert
  include SS::Document

  field :training_state, type: String
  field :kind_warning, type: String
  field :kind_advisory, type: String

  def training_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end
end
