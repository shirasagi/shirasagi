namespace :gws do
  namespace :reminder do
    namespace :notification do
      task deliver: :environment do
        ::Tasks::Gws::Reminder.deliver_notification
      end
    end
  end
end
