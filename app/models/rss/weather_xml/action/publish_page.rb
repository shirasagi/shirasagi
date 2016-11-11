class Rss::WeatherXml::Action::PublishPage < Rss::WeatherXml::Action::Base
  belongs_to :publish_to, class_name: "Cms::Node"
  field :publish_state, type: String
  permit_params :publish_to_id, :publish_state

  def publish_state_options
    %w(draft public).map { |v| [ I18n.t("views.options.state.#{v}"), v ] }
  end
end
