class Rss::WeatherXml::Filter
  include SS::Document

  embedded_in :node, class_name: "Rss::Node::WeatherXml", inverse_of: :filter
  field :name, type: String
  field :state, type: String
  belongs_to :trigger, class_name: "Rss::WeatherXml::Trigger::Base"
  belongs_to :action, class_name: "Rss::WeatherXml::Action::Base"
  permit_params :name, :state, :trigger_id, :action_id

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
