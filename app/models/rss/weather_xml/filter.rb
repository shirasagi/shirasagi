class Rss::WeatherXml::Filter
  include SS::Document
  include Rss::Addon::WeatherXml::Trigger::WeatherAlert
  include Rss::Addon::WeatherXml::Action::PublishPage

  embedded_in :node, class_name: "Rss::Node::WeatherXml", inverse_of: :filter
  field :name, type: String
  field :state, type: String
  field :trigger_type, type: String
  field :action_type, type: String
  permit_params :name, :state, :trigger_type, :action_type

  class << self
    def search(params = {})
      self.all
    end

    delegate :allowed?, to: 'Rss::Node::WeatherXml'
  end

  delegate :allowed?, to: :node

  def state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end
end
