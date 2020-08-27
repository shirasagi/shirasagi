namespace :gws do
  namespace :presence do
    task reset: :environment do
      ::Tasks::Gws::Presence.reset
    end
  end
end
