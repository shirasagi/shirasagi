class Gws::Attendance::History
  extend SS::Translation
  include SS::Document

  embedded_in :time_card

  field :date, type: DateTime
  field :action, type: String
end
