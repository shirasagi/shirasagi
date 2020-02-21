namespace :ss do
  task migrate: :environment do
    SS::Migration.migrate
  end

  namespace :migrate do
    task status: :environment do
      SS::Migration.status
    end

    task up: :environment do
      SS::Migration.up
    end
  end
end
