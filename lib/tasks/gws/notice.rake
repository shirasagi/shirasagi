namespace :gws do
  namespace :notice do
    namespace :notification do
      task deliver: :environment do
        ::Tasks::Gws::Notice.deliver_notification
      end
    end
  end
 end
