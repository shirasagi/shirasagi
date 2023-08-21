module Gws::Addon::Portal::MonitorSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :portal_monitor_state, type: String, default: "show"
    permit_params :portal_monitor_state
    validates :portal_monitor_state, inclusion: { in: %w(show hide), allow_blank: true }
  end

  def portal_monitor_state_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def show_portal_monitor?
    portal_monitor_state.blank? || portal_monitor_state == "show"
  end
end
