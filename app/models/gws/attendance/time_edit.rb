class Gws::Attendance::TimeEdit
  include Gws::Model::Attendance::TimeEdit

  validates :in_reason, presence: true, length: { maximum: 80 }
end
