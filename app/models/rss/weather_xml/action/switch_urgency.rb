class Rss::WeatherXml::Action::SwitchUrgency < Rss::WeatherXml::Action::Base
  belongs_to :urgency_layout, class_name: "Cms::Layout"
  permit_params :urgency_layout_id

  def execute(page, context)
    node = Urgency::Node::Layout.site(context.site).order_by(depth: 1, id: 1).first
    node.switch_layout(urgency_layout)
  end
end
