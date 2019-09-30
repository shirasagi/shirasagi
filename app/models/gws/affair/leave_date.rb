class Gws::Affair::LeaveDate
  include SS::Document

  embedded_in :file, class_name: "Gws::Addon::Affair::LeaveFile"

  field :date, type: DateTime
  field :start_at, type: DateTime
  field :end_at, type: DateTime
  field :working_minute, type: Integer
  field :minute, type: Integer

  validates :date, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :working_minute, presence: true
  validates :minute, presence: true
end
