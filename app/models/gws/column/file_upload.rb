class Gws::Column::FileUpload < Gws::Column::Base

  field :upload_file_count, type: Integer, default: 1
  permit_params :upload_file_count

  def serialize_value(file_ids)
    Gws::Column::Value::FileUpload.new(
      column_id: self.id, name: self.name, order: self.order, file_ids: file_ids
    )
  end
end
