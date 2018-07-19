namespace :gws do
  namespace :reminder do
    namespace :notification do
      # this rake task is intended for backward compatibility
      # use `gws:notification:deliver` task
      task deliver: :environment do
        ::Tasks::Gws::Notification.deliver_reminder
      end
    end
  end
end
