class Sys::GroupImportJob < SS::ApplicationJob
  include SS::GroupImportBase

  self.mode = :sys
  self.model = Sys::Group

  private

  def find_or_initialize_item(row)
    id = value(row, :id)
    item = Sys::Group.where(id: id).first if id.present?
    item || Sys::Group.new
  end
end
