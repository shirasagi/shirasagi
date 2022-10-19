class Gws::Attendance::Record
  include Gws::Model::Attendance::Record

  embedded_in :time_card, class_name: 'Gws::Attendance::TimeCard'
end
