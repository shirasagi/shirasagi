namespace :gws do
  namespace :notification do
    task deliver: :environment do
      ::Tasks::Gws::Notification.deliver
    end
  end
 end
