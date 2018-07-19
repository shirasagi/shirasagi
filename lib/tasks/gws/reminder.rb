module Tasks
  module Gws
    class Reminder
      extend Tasks::Gws::Base

      class << self
        def deliver_notification
          opts = {}
          opts[:from] = Time.zone.at(Integer(ENV['from'])) rescue Time.zone.parse(ENV['from']) if ENV['from']
          opts[:to] = Time.zone.at(Integer(ENV['to'])) rescue Time.zone.parse(ENV['to']) if ENV['to']

          each_sites do |site|
            puts site.name
            ::Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now(opts)
          end
        end
      end
    end
  end
end
