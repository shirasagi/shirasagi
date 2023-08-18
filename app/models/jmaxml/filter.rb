class Jmaxml::Filter
  include SS::Document

  embedded_in :node, class_name: "Rss::Node::WeatherXml", inverse_of: :filter
  field :name, type: String
  field :state, type: String, default: 'enabled'
  embeds_ids :triggers, class_name: "Jmaxml::Trigger::Base"
  embeds_ids :actions, class_name: "Jmaxml::Action::Base"
  validates :name, presence: true, length: { maximum: 40 }
  validates :state, presence: true, inclusion: { in: %w(enabled disabled), allow_blank: true }
  validates :trigger_ids, presence: true
  validates :action_ids, presence: true
  permit_params :name, :state
  permit_params trigger_ids: [], action_ids: []

  scope :and_enabled, -> { where(state: 'enabled') }

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
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def trigger_options
    Jmaxml::Trigger::Base.site(node.site).pluck(:name, :id)
  end

  def action_options
    Jmaxml::Action::Base.site(node.site).pluck(:name, :id)
  end

  def execute(page, context)
    trigger = triggers.first
    return if trigger.blank?
    trigger = trigger["_type"].constantize.find(trigger.id)

    xmldoc = REXML::Document.new(page.weather_xml)
    context[:xmldoc] = xmldoc

    trigger.verify(page, context) do
      actions.each do |action|
        action = action["_type"].constantize.find(action.id)
        action.execute(page, context)
      end
    end
  end
end
