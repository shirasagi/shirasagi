class Gws::Column::FileUpload < Gws::Column::Base

  field :place_holder, type: String
  field :upload_file_count, type: Integer, default: 1
  permit_params :place_holder, :upload_file_count

  def serialize_value(file_ids)
    ret = Gws::Column::Value::FileUpload.new(
      column_id: self.id, name: self.name, order: self.order, file_ids: file_ids
    )
    ret.text_index = ret.value
    ret
  end
end
