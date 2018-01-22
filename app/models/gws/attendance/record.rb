class Gws::Attendance::Record
  extend SS::Translation
  include SS::Document

  embedded_in :time_card

  field :date, type: DateTime
  field :enter, type: DateTime
  field :leave, type: DateTime
  field :break_enter1, type: DateTime
  field :break_leave1, type: DateTime
  field :break_enter2, type: DateTime
  field :break_leave2, type: DateTime
  field :break_enter3, type: DateTime
  field :break_leave3, type: DateTime
  field :memo, type: String
end
