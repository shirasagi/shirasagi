class Gws::Memo::MessageImportJob < Gws::ApplicationJob
  def perform(importer_id)
    importer = Gws::Memo::MessageImporter.site(site).find(importer_id)
    importer.import_messages
  ensure
    importer.create_notify
    importer.destroy
  end
end
