namespace :cms do
  namespace :form_db do
    task import: :environment do
      puts "# form_db: import from url"
      Cms::FormDb.import_setted.each do |db|
        puts db.name
        db.perform_import
      end
    end
  end
end
