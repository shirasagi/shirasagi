class Rss::WeatherXml::Action::PublishPage
  include SS::Document

  belongs_to :node, class_name: "Cms::Node"
  field :state, type: String

  def state_options
    %w(draft public).map { |v| [ I18n.t("views.options.state.#{v}"), v ] }
  end
end
