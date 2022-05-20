module Cms::Addon
  module Line::DeliverCondition::Body
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::Line::DeliverCondition::Model

    def deliver_action
      "multicast"
    end

    def deliver_condition_label
      condition_label
    end

    def extract_deliver_members
      extract_conditional_members
    end
  end
end
