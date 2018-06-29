class Gws::Attendance::Record
  extend SS::Translation
  include SS::Document

  embedded_in :time_card, class_name: 'Gws::Attendance::TimeCard'

  cattr_accessor(:punchable_field_names)

  self.punchable_field_names = %w(enter leave)

  field :date, type: DateTime
  field :enter, type: DateTime
  field :leave, type: DateTime
  SS.config.gws.attendance['max_break'].times do |i|
    field "break_enter#{i + 1}", type: DateTime
    field "break_leave#{i + 1}", type: DateTime
    self.punchable_field_names << "break_enter#{i + 1}"
    self.punchable_field_names << "break_leave#{i + 1}"
  end
  field :memo, type: String
  self.punchable_field_names = self.punchable_field_names.freeze

  def find_latest_history(field_name)
    criteria = time_card.histories.where(date: date.in_time_zone('UTC'), field_name: field_name)
    criteria.order_by(created: -1).first
  end

  def calc_working_time
    return if enter.blank? || leave.blank?
    duration = (leave - enter).to_i
    Time::EPOCH + duration
  end
end
