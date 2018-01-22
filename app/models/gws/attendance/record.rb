class Gws::Attendance::Record
  extend SS::Translation
  include SS::Document

  embedded_in :time_card

  field :date, type: DateTime
  field :enter, type: DateTime
  field :leave, type: DateTime
  SS.config.gws.attendance['max_break'].times do |i|
    field "break_enter#{i + 1}", type: DateTime
    field "break_leave#{i + 1}", type: DateTime
  end
  field :memo, type: String

  def find_latest_reason(field_name)
    criteria = time_card.histories.where(date: date)
    criteria.where(field_name: field_name)
    history = criteria.order_by(created: -1).first
    history.try(:reason).presence
  end
end
