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
  end
end
