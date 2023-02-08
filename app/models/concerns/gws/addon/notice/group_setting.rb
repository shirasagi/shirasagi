module Gws::Addon::Notice::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :notice_new_days, type: Integer
    field :notice_severity, type: String, default: "all"
    field :notice_browsed_state, type: String, default: "unread"
    field :notice_toggle_browsed, type: String, default: "button"

    permit_params :notice_new_days, :notice_browsed_state, :notice_severity, :notice_toggle_browsed
  end

  def notice_new_days
    self[:notice_new_days].presence || 7
  end

  def notice_severity_options
    %w(all high).map { |m| [I18n.t("gws/notice.options.severity.#{m}"), m] }
  end

  def notice_browsed_state_options
    %w(both unread read).map { |m| [I18n.t("gws/board.options.browsed_state.#{m}"), m] }
  end

  def notice_toggle_browsed_options
    %w(button read).map { |m| [I18n.t("gws/notice.options.toggle_browsed.#{m}"), m] }
  end

  def notice_toggle_by_button?
    notice_toggle_browsed == "button"
  end

  def notice_toggle_by_read?
    notice_toggle_browsed == "read"
  end
end
