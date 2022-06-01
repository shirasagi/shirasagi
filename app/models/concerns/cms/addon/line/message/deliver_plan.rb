module Cms::Addon
  module Line::Message::DeliverPlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      has_many :deliver_plans, class_name: "Cms::Line::DeliverPlan", dependent: :destroy
    end

    def ready_plans
      deliver_plans.where(state: "ready").to_a
    end

    def next_plan
      ready_plans.first
    end

    def deliver_date
      next_plan.try(:deliver_date)
    end
  end
end
