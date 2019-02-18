namespace :ss do
  namespace :session_lifetime do
    task hard: :environment do
      SS::SessionStore.set_lifetime_limit(limit: Integer(ENV["limit"]))
    end
  end
end
