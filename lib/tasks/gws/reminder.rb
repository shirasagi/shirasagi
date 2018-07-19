module Tasks
  module Gws
    class Reminder
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

        private

        def each_sites
          if name = ENV['site']
            ::Gws::Group.where(name: name).each do |site|
              yield site
            end
            return
          end

          ids = ::Gws::Group.all.map { |group| group.root.try(:id) }.uniq.compact
          ::Gws::Group.where(:id.in => ids).each do |site|
            yield site
          end
        end
      end
    end
  end
end
