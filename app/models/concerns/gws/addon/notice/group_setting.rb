module Gws::Addon::Notice::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :notice_new_days, type: Integer
    field :notice_severity, type: String, default: "all"
    field :notice_browsed_state, type: String, default: "both"
    field :notice_toggle_browsed, type: String, default: "button"
    field :notice_folder_navi_open_state, type: String, default: "default"

    validates :notice_severity, inclusion: { in: %w(all high normal), allow_blank: true }
    validates :notice_browsed_state, inclusion: { in: %w(both unread read), allow_blank: true }
    validates :notice_toggle_browsed, inclusion: { in: %w(button read), allow_blank: true }
    validates :notice_folder_navi_open_state, inclusion: { in: %w(default expand_all), allow_blank: true }

    permit_params :notice_new_days, :notice_severity, :notice_browsed_state, :notice_toggle_browsed
    permit_params :notice_folder_navi_open_state
  end

  def notice_new_days
    self[:notice_new_days].presence || 7
  end

  def notice_severity_options
    %w(all high normal).map { |m| [I18n.t("gws/notice.options.severity.#{m}"), m] }
  end

  def notice_browsed_state_options
    %w(both unread read).map { |m| [I18n.t("gws/board.options.browsed_state.#{m}"), m] }
  end

  def notice_toggle_browsed_options
    %w(button read).map { |m| [I18n.t("gws/notice.options.toggle_browsed.#{m}"), m] }
  end

  def notice_folder_navi_open_state_options
    %w(default expand_all).map { [I18n.t("gws/notice.options.notice_folder_navi_open_state.#{_1}"), _1] }
  end

  def notice_toggle_by_button?
    notice_toggle_browsed == "button"
  end

  def notice_toggle_by_read?
    notice_toggle_browsed == "read"
  end

  def notice_folder_navi_expand_all?
    notice_folder_navi_open_state == "expand_all"
  end
end
