class Inquiry::Answer::Data
  include Mongoid::Document

  field :column_id, type: Integer
  field :value, type: String

  belongs_to :column, foreign_key: :column_id, class_name: "Inquiry::Column"
end
