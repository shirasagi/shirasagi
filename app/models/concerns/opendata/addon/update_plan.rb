module Opendata::Addon::UpdatePlan
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :update_plan, type: String
    field :update_plan_date, type: DateTime
    field :update_plan_unit, type: String
    field :update_plan_mail_state, type: String, default: "disabled"

    permit_params :update_plan, :update_plan_date, :update_plan_unit, :update_plan_date_mail_state
  end

  def update_plan_unit_options
    %w(yearly monthly).map do |v|
      [ I18n.t("opendata.update_plan_unit_options.#{v}"), v ]
    end
  end

  def update_plan_mail_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end
end
