namespace :ss do
  task :migrate => :environment do
    SS::Migration.migrate
  end
end
