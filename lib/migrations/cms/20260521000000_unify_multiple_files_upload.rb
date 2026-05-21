class SS::Migration20260521000000
  include SS::Migration::Base

  COLUMN_TYPE_MAP = {
    "Cms::Column::MultipleImagesUpload" => "image",
    "Cms::Column::MultipleAttachmentsUpload" => "attachment"
  }.freeze

  VALUE_TYPE_MAP = {
    "Cms::Column::Value::MultipleImagesUpload" => "image",
    "Cms::Column::Value::MultipleAttachmentsUpload" => "attachment"
  }.freeze

  NEW_COLUMN_TYPE = "Cms::Column::MultipleFilesUpload".freeze
  NEW_VALUE_TYPE = "Cms::Column::Value::MultipleFilesUpload".freeze

  def change
    migrate_columns
    migrate_page_column_values
  end

  private

  def migrate_columns
    columns = Cms::Column::Base.collection
    COLUMN_TYPE_MAP.each do |old_type, file_type|
      columns.find(_type: old_type).each do |doc|
        columns.update_one(
          { _id: doc["_id"] },
          { "$set" => { _type: NEW_COLUMN_TYPE, file_type: file_type } }
        )
      end
    end
  end

  def migrate_page_column_values
    pages = Cms::Page.collection
    pages.find("column_values._type" => { "$in" => VALUE_TYPE_MAP.keys }).each do |doc|
      values = doc["column_values"].map do |cv|
        VALUE_TYPE_MAP.key?(cv["_type"]) ? cv.merge("_type" => NEW_VALUE_TYPE) : cv
      end
      pages.update_one({ _id: doc["_id"] }, { "$set" => { "column_values" => values } })
    end
  end
end
