namespace :gws do
  namespace :reminder do
    namespace :notification do
      task :deliver => :environment do
        site = Gws::Group.where(name: ENV['site']).first
        puts "Site not found: #{ENV['site']}" or exit unless site

        opts = {}
        opts[:from] = Time.zone.parse(ENV['from']) if ENV['from']
        opts[:to] = Time.zone.parse(ENV['to']) if ENV['to']

        Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now(opts)
      end
    end
  end
end
