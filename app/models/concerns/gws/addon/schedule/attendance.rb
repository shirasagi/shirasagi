module Gws::Addon::Schedule::Attendance
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :attendance_check_state, type: String
    embeds_many :attendances, class_name: 'Gws::Schedule::Attendance', cascade_callbacks: true
    validates :attendance_check_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
    permit_params :attendance_check_state

    scope :no_absence, ->(user){ self.not(attendances: { '$elemMatch' => { user_id: user.id, attendance_state: 'absence' }}) }
  end

  def attendance_check_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def attendance_check_enabled?
    attendance_check_state == 'enabled'
  end

  def attendance_absence_all?
    absence = attendances.select { |c| c.attendance_state == 'absence' }
    absence.size >= overall_members.active.size
  end
end
