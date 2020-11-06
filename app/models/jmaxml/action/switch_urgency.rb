class Jmaxml::Action::SwitchUrgency < Jmaxml::Action::Base
  include Jmaxml::Addon::Action::SwitchUrgency

  def execute(page, context)
    node = Urgency::Node::Layout.find_related_urgency_node(context.site)
    node.switch_layout(urgency_layout)
  end
end
