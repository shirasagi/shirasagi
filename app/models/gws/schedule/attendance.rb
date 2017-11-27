class Gws::Schedule::Attendance
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Schedule
  include Gws::Addon::GroupPermission

  set_permission_name 'gws_schedule_plans'

  field :attendance_state, type: String

  validates :attendance_state, presence: true, inclusion: { in: %w(unknown attendance absence), allow_blank: true }
  validates :user_id, uniqueness: { scope: :schedule_id }

  permit_params :attendance_state

  def attendance_state_options
    %w(unknown attendance absence).map do |v|
      [ I18n.t("gws/schedule.options.attendance_state.#{v}"), v ]
    end
  end
end
