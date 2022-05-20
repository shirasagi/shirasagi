module Cms::Addon
  module Line::Message::DeliverCondition
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::Line::DeliverCondition::Model

    included do
      field :deliver_condition_state, type: String, default: 'broadcast'
      belongs_to :deliver_condition, class_name: "Cms::Line::DeliverCondition"

      validates :deliver_condition_state, presence: true
      permit_params :deliver_condition_state, :deliver_condition_id
    end

    def deliver_condition_state_options
      I18n.t("cms.options.line_deliver_condition_state").map { |k, v| [v, k] }
    end

    def deliver_action
      return "broadcast" if deliver_condition_state == "broadcast"
      return "multicast" if deliver_condition_state =~ /^multicast_with_/
      nil
    end

    def deliver_condition_label
      case deliver_condition_state
      when "multicast_with_no_condition"
        nil
      when "multicast_with_registered_condition"
        deliver_condition ? deliver_condition.name_with_order : I18n.t("ss.options.state.deleted")
      when "multicast_with_input_condition"
        condition_label
      else
        nil
      end
    end

    def extract_deliver_members
      case deliver_condition_state
      when "multicast_with_no_condition"
        extract_multicast_members
      when "multicast_with_registered_condition"
        deliver_condition ? deliver_condition.extract_conditional_members : empty_members
      when "multicast_with_input_condition"
        extract_conditional_members
      else
        empty_members
      end
    end
  end
end
