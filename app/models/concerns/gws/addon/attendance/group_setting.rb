module Gws::Addon::Attendance::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    attr_accessor :in_attendance_time_change_hour

    field :attendance_time_changed_at, type: DateTime, default: Time::EPOCH + 3.hours
    SS.config.gws.attendance['max_break'].times do |i|
      field "attendance_break_time_state#{i + 1}", type: String
      field "attendance_break_enter_label#{i + 1}", type: String
      field "attendance_break_leave_label#{i + 1}", type: String
      alias_method("attendance_break_time_state#{i + 1}_options", :attendance_break_time_options)
      permit_params "attendance_break_time_state#{i + 1}"
      permit_params "attendance_break_enter_label#{i + 1}"
      permit_params "attendance_break_leave_label#{i + 1}"
    end

    permit_params :in_attendance_time_change_hour

    before_validation :set_attendance_time_changed_at
  end

  def attendance_time_changed_at_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  def attendance_break_time_options
    %w(hide show).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def calc_attendance_date(time = Time.zone.now)
    Time.zone.at(time - attendance_time_changed_at).beginning_of_day
  end

  private

  def set_attendance_time_changed_at
    if in_attendance_time_change_hour.blank?
      self.attendance_time_changed_at = nil
    else
      self.attendance_time_changed_at = Time::EPOCH + Integer(in_attendance_time_change_hour).hours
    end
  end
end
