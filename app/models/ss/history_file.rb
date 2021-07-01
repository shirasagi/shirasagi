class SS::HistoryFile
  include SS::Model::File
  include SS::Relation::Thumb

  field :site_id, type: Integer
  field :node_id, type: Integer

  belongs_to :original, class_name: "SS::File"

  default_scope ->{ where(model: "ss/history_file").order_by(created: -1) }

  def restore
    item = SS::ReplaceFile.find(original_id)
    item.in_file = uploaded_file
    item.filename = filename
    item.name = name
    item.save
  end
end
