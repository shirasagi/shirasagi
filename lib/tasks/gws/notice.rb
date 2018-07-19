module Tasks
  module Gws
    class Notice
      extend Tasks::Gws::Base

      class << self
        def deliver_notification
          each_sites do |site|
            puts site.name
            ::Gws::Notice::NotificationJob.bind(site_id: site.id).perform_now
          end
        end
      end
    end
  end
end
