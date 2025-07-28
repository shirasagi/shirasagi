namespace :gws do
  namespace :affair do
    namespace :notification do
      task deliver: :environment do
        ::Tasks::Gws::Affair::Notification.deliver
      end
    end
  end
end
