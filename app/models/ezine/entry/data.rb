class Ezine::Entry::Data
  include Mongoid::Document

  field :column_id, type: Integer
  field :value, type: String
  field :values, type: Array

  belongs_to :column, foreign_key: :column_id, class_name: "Ezine::Column"
  embedded_in :entry, class_name: "Ezine::Entry"
end
