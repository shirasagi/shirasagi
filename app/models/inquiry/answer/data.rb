class Inquiry::Answer::Data
  include Mongoid::Document

  field :column_id, type: Integer
  field :value, type: String
  field :values, type: Array
  field :confirm, type: String

  belongs_to :column, foreign_key: :column_id, class_name: "Inquiry::Column"

  def file
    return nil if column.nil?
    return nil if column.input_type != "upload_file"
    @_file ||= (SS::File.find(values[0]) rescue nil)
  end
end
