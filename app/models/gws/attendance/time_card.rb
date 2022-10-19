class Gws::Attendance::TimeCard
  include Gws::Model::Attendance::TimeCard

  embeds_many :histories, class_name: 'Gws::Attendance::History'
  embeds_many :records, class_name: 'Gws::Attendance::Record'
end
