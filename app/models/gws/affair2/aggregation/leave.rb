class Gws::Affair2::Aggregation::Leave
  extend SS::Translation
  include SS::Document

  #embedded_in :day, class_name: 'Gws::Affair2::Aggregation::Month'
  #embedded_in :month, class_name: 'Gws::Affair2::Aggregation::Month'

  field :leave_type, type: String, default: 0
  field :minutes, type: Integer, default: 0
end
