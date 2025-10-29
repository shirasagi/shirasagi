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

    %w(back_number calendar).each do |name|
      field "notice_#{name}_menu_state", type: String, default: 'show'
      field "notice_#{name}_menu_label", type: String, localize: true

      validates "notice_#{name}_menu_state", inclusion: { in: %w(show hide), allow_blank: true }
      validates "notice_#{name}_menu_label", length: { maximum: 40 }

      permit_params "notice_#{name}_menu_state", "notice_#{name}_menu_label"

      alias_method("notice_#{name}_menu_state_options", "notice_menu_state_options")
      define_method("notice_#{name}_menu_invisible?") do
        send("notice_#{name}_menu_state") == "hide"
      end
      define_method("notice_#{name}_menu_visible?") do
        !send("notice_#{name}_menu_invisible?")
      end
    end
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

  def notice_menu_state_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def notice_back_number_menu_label_placeholder
    I18n.t("gws/notice.back_number")
  end

  def notice_calendar_menu_label_placeholder
    I18n.t('ss.navi.calendar')
  end
end
