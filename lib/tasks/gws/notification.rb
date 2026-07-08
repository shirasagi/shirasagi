module Tasks
  module Gws
    class Notification
      class << self
        def deliver
          opts = {}
          opts[:from] = Time.zone.at(Integer(ENV['from'])) rescue Time.zone.parse(ENV['from']) if ENV['from']
          opts[:to] = Time.zone.at(Integer(ENV['to'])) rescue Time.zone.parse(ENV['to']) if ENV['to']

          Tasks::Gws::Base.each_sites do |site|
            puts site.name
            ::Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now(opts)
            ::Gws::Notice::NotificationJob.bind(site_id: site.id).perform_now
            ::Gws::Survey::NotificationJob.bind(site_id: site.id).perform_now
            ::Gws::Board::NotificationJob.bind(site_id: site.id).perform_now
            ::Gws::Affair::NotifyCompensatoryFileJob.bind(site_id: site.id).perform_now
          end
        end

        # this method is intended for backward compatibility
        # use `deliver` method
        def deliver_reminder
          opts = {}
          opts[:from] = Time.zone.at(Integer(ENV['from'])) rescue Time.zone.parse(ENV['from']) if ENV['from']
          opts[:to] = Time.zone.at(Integer(ENV['to'])) rescue Time.zone.parse(ENV['to']) if ENV['to']

          Tasks::Gws::Base.each_sites do |site|
            puts site.name
            ::Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now(opts)
          end
        end

        # this method is intended for backward compatibility
        # use `deliver` method
        def deliver_notice
          Tasks::Gws::Base.each_sites do |site|
            puts site.name
            ::Gws::Notice::NotificationJob.bind(site_id: site.id).perform_now
          end
        end
      end
    end
  end
end
