namespace :cms do
  namespace :form_db do
    task import: :environment do
      Cms::FormDb.import_setted.each do |db|
        db.perform_import
      end
    end
  end
end
