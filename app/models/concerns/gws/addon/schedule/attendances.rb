module Gws::Addon::Schedule::Attendances
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :attendance_check_state, type: String
    has_many :attendances, class_name: 'Gws::Schedule::Attendance', dependent: :destroy
    validates :attendance_check_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
    permit_params :attendance_check_state
  end

  def attendance_check_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def attendance_check_enabled?
    attendance_check_state == 'enabled'
  end

  def contains_unknown_attendance?
    ids = sorted_overall_members.map(&:id)
    return true if attendances.in(user_id: ids).count != ids.length

    attendances.in(user_id: ids).where(attendance_state: 'unknown').present?
  end
end
