module Gws::Addon::Schedule::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    %w(personal group custom_group group_all facility).each do |name|
      field "schedule_#{name}_tab_state", type: String, default: 'show'
      permit_params "schedule_#{name}_tab_state"
      alias_method("schedule_#{name}_tab_state_options", "schedule_tab_state_options")
      define_method("schedule_#{name}_tab_visible?") do
        schedule_tab_visible?(name)
      end
    end
    %w(personal group_all facility).each do |name|
      field "schedule_#{name}_tab_label", type: String, localize: true
      permit_params "schedule_#{name}_tab_label"
    end

    attr_accessor :in_schedule_max_file_size_mb

    field :schedule_max_month, type: Integer
    field :schedule_max_years, type: Integer
    field :schedule_min_hour, type: Integer, default: 8
    field :schedule_max_hour, type: Integer, default: 22
    field :schedule_first_wday, type: Integer, default: 0
    field :schedule_max_file_size, type: Integer, default: 0
    field :todo_delete_threshold, type: Integer, default: 3
    field :schedule_attachment_state, type: String, default: 'allow'
    field :schedule_drag_drop_state, type: String, default: 'allow'
    field :schedule_custom_group_extra_state, type: String

    permit_params :schedule_max_month, :schedule_max_years
    permit_params :schedule_min_hour, :schedule_max_hour, :schedule_first_wday
    permit_params :schedule_max_file_size, :in_schedule_max_file_size_mb
    permit_params :todo_delete_threshold
    permit_params :schedule_attachment_state, :schedule_drag_drop_state
    permit_params :schedule_custom_group_extra_state

    before_validation :set_schedule_max_file_size

    validates :schedule_max_file_size, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :schedule_attachment_state, inclusion: { in: %w(allow deny), allow_blank: true }
    validates :schedule_drag_drop_state, inclusion: { in: %w(allow deny), allow_blank: true }
    validates :schedule_custom_group_extra_state, inclusion: { in: %w(creator_name), allow_blank: true }
    validate :validate_schedule_hours, if: ->{ schedule_min_hour.present? && schedule_max_hour.present? }
  end

  def schedule_max_month
    self[:schedule_max_month].presence || 3
  end

  def schedule_max_years
    self[:schedule_max_years].presence || 1
  end

  def schedule_max_at
    year = (Time.zone.today << schedule_max_month).year + schedule_max_years + 1
    Date.new year, schedule_max_month, -1
  end

  def schedule_min_time
    hour = self[:schedule_min_hour].presence || 8
    "#{hour}:00"
  end

  def schedule_max_time
    hour = self[:schedule_max_hour].presence || 22
    "#{hour}:00"
  end

  def schedule_max_month_options
    1..12
  end

  def schedule_max_years_options
    (0..10).map { |m| ["+#{m}", m] }
  end

  def schedule_min_hour_options
    (0..24).map { |m| [m, m] }
  end

  def schedule_first_wday_options
    options = I18n.t("date.day_names").map.with_index { |v, idx| [v, idx] }
    options << [I18n.t("gws/schedule.today_wday"), -1]
    options
  end

  def schedule_first_day
    (schedule_first_wday >= 0) ? schedule_first_wday: Time.zone.today.wday
  end

  def schedule_max_hour_options
    schedule_min_hour_options
  end

  def todo_delete_threshold_options
    I18n.t('gws/schedule/group_setting.options.todo_delete_threshold').
      map.
      with_index.
      to_a
  end

  def todo_delete_threshold_name
    I18n.t('gws/schedule/group_setting.options.todo_delete_threshold')[todo_delete_threshold]
  end

  def schedule_attachment_state_options
    %w(allow deny).map do |v|
      [ I18n.t("gws/schedule.options.schedule_attachment_state.#{v}"), v ]
    end
  end

  def schedule_drag_drop_state_options
    %w(allow deny).map do |v|
      [ I18n.t("gws/schedule.options.schedule_drag_drop_state.#{v}"), v ]
    end
  end

  def schedule_attachment_denied?
    schedule_attachment_state == 'deny'
  end

  def schedule_attachment_allowed?
    !schedule_attachment_denied?
  end

  def schedule_drag_drop_denied?
    schedule_drag_drop_state == 'deny'
  end

  def schedule_drag_drop_allowed?
    !schedule_drag_drop_denied?
  end

  def schedule_tab_state_options
    %w(show hide).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def schedule_tab_visible?(name)
    send("schedule_#{name}_tab_state") != 'hide'
  end

  def schedule_personal_tab_placeholder
    I18n.t("gws/schedule.tabs.personal")
  end

  def schedule_group_all_tab_placeholder
    I18n.t("gws/schedule.tabs.group")
  end

  def schedule_facility_tab_placeholder
    I18n.t("gws/schedule.tabs.facility")
  end

  def schedule_custom_group_extra_state_options
    %w(creator_name).map do |v|
      [ I18n.t("gws/schedule.options.schedule_custom_group_extra_state.#{v}"), v ]
    end
  end

  private

  def set_schedule_max_file_size
    return if in_schedule_max_file_size_mb.blank?
    self.schedule_max_file_size = Integer(in_schedule_max_file_size_mb) * 1_024 * 1_024
  end

  def validate_schedule_hours
    if schedule_min_hour >= schedule_max_hour
      errors.add :schedule_max_hour, :greater_than, count: t(:schedule_min_hour)
    end
  end
end
