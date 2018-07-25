namespace :ss do
  task models: :environment do
    require_relative "./models"
    Tasks::SS::Models.call
  end
end
