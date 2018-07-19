module Tasks
  module Gws
    class Notice
      class << self
        def deliver_notification
          each_sites do |site|
            puts site.name
            ::Gws::Notice::NotificationJob.bind(site_id: site.id).perform_now
          end
        end

        private

        def each_sites
          name = ENV['site']
          if !name
            puts "site must be specified"
            return
          end

          ::Gws::Group.where(name: name).each do |site|
            yield site
          end
        end
      end
    end
  end
end
