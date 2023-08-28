module Gws::Addon::Affair::Flextime
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :flextime_state, type: String, default: "disabled"
    permit_params :flextime_state
  end

  def flextime?
    flextime_state == "enabled"
  end

  def flextime_state_options
    [
      [I18n.t("ss.options.state.enabled"), "enabled"],
      [I18n.t("ss.options.state.disabled"), "disabled"],
    ]
  end
end
