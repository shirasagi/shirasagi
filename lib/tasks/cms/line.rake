namespace :cms do
  namespace :line do
    task :deliver, [:site] => :environment do |task, args|
      ::Tasks::Cms::Base.with_site(args[:site] || ENV['site']) do |site|
        job = ::Cms::Line::DeliverReservedJob.bind(site_id: site)
        job.perform_now
      end
    end

    task :apply_richmenu, [:site] => :environment do |task, args|
      ::Tasks::Cms::Base.with_site(args[:site] || ENV['site']) do |site|
        job = ::Cms::Line::ApplyRichmenuJob.bind(site_id: site)
        job.perform_now
      end
    end

    task :update_statistics, [:site] => :environment do |task, args|
      ::Tasks::Cms::Base.with_site(args[:site] || ENV['site']) do |site|
        job = ::Cms::Line::UpdateStatisticsJob.bind(site_id: site)
        job.perform_now
      end
    end

    task :mail_import, [:site] => :environment do |task, args|
      ::Tasks::Cms::Base.with_site(args[:site] || ENV['site']) do |site|
        puts "Please input mail hanlder filename: filename=[filename]" or exit if ENV['filename'].blank?

        item = Cms::Line::MailHandler.site(site).and_enabled.find_by(filename: ENV['filename']) rescue nil
        raise "handler not found!" if item.nil?

        item.handle_message($stdin.read)
      end
    end
  end
end
