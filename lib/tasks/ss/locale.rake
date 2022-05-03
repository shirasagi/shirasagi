namespace :ss do
  task locale: :environment do
    ::Tasks::SS::Locale.generate
  end
end
