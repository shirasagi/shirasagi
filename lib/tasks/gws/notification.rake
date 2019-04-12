namespace :gws do
  namespace :notification do
    task deliver: :environment do
      ::Tasks::SS::Notification.deliver
    end
  end
 end
