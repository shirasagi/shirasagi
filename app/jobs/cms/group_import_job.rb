class Cms::GroupImportJob < Cms::ApplicationJob
  include SS::GroupImportBase

  self.mode = :cms
  self.model = Cms::Group

  private

  def find_or_initialize_item(row)
    id = value(row, :id)
    item = Cms::Group.site(site).where(id: id).first if id.present?
    item || Cms::Group.new(cur_site: site)
  end
end
