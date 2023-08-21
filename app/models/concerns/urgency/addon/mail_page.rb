module Urgency::Addon
  module MailPage
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :urgency_state, type: String, default: "disabled"
      belongs_to :urgency_node, class_name: "Urgency::Node::Layout"
      permit_params :urgency_node_id, :urgency_state
    end

    def urgency_state_options
      %w(disabled enabled).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
    end

    def urgency_enabled?
      urgency_state == "enabled" && urgency_node && urgency_node.urgency_mail_page_layout
    end

    def urgency_switch_layout
      urgency_node.switch_layout(urgency_node.urgency_mail_page_layout)
    end
  end
end
