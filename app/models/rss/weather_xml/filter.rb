class Rss::WeatherXml::Filter
  include SS::Document

  embedded_in :node, class_name: "Rss::Node::WeatherXml", inverse_of: :filter
  field :name, type: String
  field :state, type: String
  embeds_ids :triggers, class_name: "Rss::WeatherXml::Trigger::Base"
  embeds_ids :actions, class_name: "Rss::WeatherXml::Action::Base"
  validates :name, presence: true, length: { maximum: 40 }
  validates :state, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }
  validates :trigger_ids, presence: true
  validates :action_ids, presence: true
  permit_params :name, :state
  permit_params trigger_ids: [], action_ids: []

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

    delegate :allowed?, to: 'Rss::Node::WeatherXml'
  end

  delegate :allowed?, to: :node

  def state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end

  def trigger_options
    Rss::WeatherXml::Trigger::Base.site(node.site).pluck(:name, :id)
  end

  def action_options
    Rss::WeatherXml::Action::Base.site(node.site).pluck(:name, :id)
  end
end
