module Tasks
  module Gws
    class Notification
      class << self
        def deliver
          opts = {}
          opts[:from] = Time.zone.at(Integer(ENV['from'])) rescue Time.zone.parse(ENV['from']) if ENV['from']
          opts[:to] = Time.zone.at(Integer(ENV['to'])) rescue Time.zone.parse(ENV['to']) if ENV['to']

          each_sites do |site|
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

          each_sites do |site|
            puts site.name
            ::Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now(opts)
          end
        end

        # this method is intended for backward compatibility
        # use `deliver` method
        def deliver_notice
          each_sites do |site|
            puts site.name
            ::Gws::Notice::NotificationJob.bind(site_id: site.id).perform_now
          end
        end

        private

        def each_sites(&block)
          name = ENV['site']
          if name
            ::Gws::Group.where(name: name).each(&block)
            return
          end

          all_ids = ::Gws::Group.all.where(name: { "$not" => /\// }).pluck(:id)
          all_ids.each_slice(20).each do |ids|
            ::Gws::Group.where(:id.in => ids).each(&block)
          end
        end
      end
    end
  end
end
