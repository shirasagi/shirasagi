module Jmaxml::Addon::Filter
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_many :filters, class_name: "Jmaxml::Filter"

    field :execute_filters_job_state, type: String

    permit_params :execute_filters_job_state
  end

  def execute_filters_job?
    execute_filters_job_state == "enabled"
  end

  def execute_filters_job_state_options
    [
      [I18n.t("ss.options.state.disabled"), "disabled"],
      [I18n.t("ss.options.state.enabled"), "enabled"],
    ]
  end
end
