class Gws::Schedule::Attendance
  include SS::Document
  include Gws::Reference::User

  embedded_in :schedule, inverse_of: :attendances
  field :attendance_state, type: String

  validates :attendance_state, presence: true, inclusion: { in: %w(unknown attendance absence), allow_blank: true }
  validates :user_id, uniqueness: { scope: :schedule_id }

  permit_params :attendance_state

  def attendance_state_options
    %w(unknown attendance absence).map do |v|
      [ I18n.t("gws/schedule.options.attendance_state.#{v}"), v ]
    end
  end

  delegate :subscribed_users, to: :_parent
end
