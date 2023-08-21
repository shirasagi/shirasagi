namespace :gws do
  namespace :notice do
    namespace :notification do
      # this rake task is intended for backward compatibility
      # use `gws:notification:deliver` task
      task deliver: :environment do
        ::Tasks::Gws::Notification.deliver_notice
      end
    end
  end
end
