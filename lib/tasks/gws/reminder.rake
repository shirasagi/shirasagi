namespace :gws do
  namespace :reminder do
    namespace :notification do
      task :deliver => :environment do
        opts = {}
        opts[:from] = Time.zone.at(Integer(ENV['from'])) rescue Time.zone.parse(ENV['from']) if ENV['from']
        opts[:to] = Time.zone.at(Integer(ENV['to'])) rescue Time.zone.parse(ENV['to']) if ENV['to']

        gws_sites.each do |site|
          puts site.name
          Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now(opts)
        end
      end

      def gws_sites
        if name = ENV['site']
          return Gws::Group.where(name: name)
        end

        ids = Gws::Group.all.map { |group| group.root.try(:id) }.uniq.compact
        Gws::Group.where(:id.in => ids)
      end
    end
  end
end
