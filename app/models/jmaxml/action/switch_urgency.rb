class Jmaxml::Action::SwitchUrgency < Jmaxml::Action::Base
  include Jmaxml::Addon::SwitchUrgency

  def execute(page, context)
    node = Urgency::Node::Layout.site(context.site).order_by(depth: 1, id: 1).first
    node.switch_layout(urgency_layout)
  end
end
