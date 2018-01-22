module Gws::Addon::Attendance::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    attr_accessor :in_attendance_time_change_hour
    field :attendance_time_changed_at, type: DateTime, default: Time::EPOCH + 3.hours
    permit_params :in_attendance_time_change_hour
    before_validation :set_attendance_time_changed_at
  end

  def attendance_time_changed_at_options
    (0..23).map do |h|
      [ "#{h}#{I18n.t('datetime.prompts.hour')}", h.to_s ]
    end
  end

  private

  def set_attendance_time_changed_at
    if in_attendance_time_change_hour.blank?
      self.attendance_time_changed_at = nil
    else
      self.attendance_time_changed_at = Time::EPOCH + in_attendance_time_change_hour.hours
    end
  end
end
