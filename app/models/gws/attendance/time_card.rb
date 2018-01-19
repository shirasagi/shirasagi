class Gws::Attendance::TimeCard
  extend SS::Translation
  include SS::Document
  include Gws::Reference::Site
  include Gws::SitePermission

  # seqid :id
  field :name, type: String
  field :year_month, type: DateTime
  embeds_many :histories, class_name: 'Attendance::History'
  embeds_many :records, class_name: 'Attendance::Record'
end
