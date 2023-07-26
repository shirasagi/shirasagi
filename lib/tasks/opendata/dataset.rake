namespace :opendata do
  task notify_dataset_plan: :environment do
    puts "Please input site: site=[www]" or exit if ENV['site'].blank?
    site = ::Cms::Site.where(host: ENV['site']).first
    ::Opendata::NotifyDatasetPlanJob.bind(site_id: site.id).perform_now
  end

  namespace :report do
    task :generate_download, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        Opendata::ResourceDownloadReportJob.bind(site_id: site.id).perform_now
      end
    end

    task :generate_access, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        Opendata::DatasetAccessReportJob.bind(site_id: site.id).perform_now
      end
    end

    task :generate_preview, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        Opendata::ResourcePreviewReportJob.bind(site_id: site.id).perform_now
      end
    end

    task :generate_all_download, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        ::Tasks::Opendata.generate_all_download_report(site)
      end
    end

    task :generate_all_access, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        ::Tasks::Opendata.generate_all_access_report(site)
      end
    end

    task :generate_all_preview, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        ::Tasks::Opendata.generate_all_preview_report(site)
      end
    end
  end

  namespace :history do
    task update_all_download: :environment do
      ::Tasks::Opendata.update_all_download_history
    end

    task update_all_preview: :environment do
      ::Tasks::Opendata.update_all_preview_history
    end

    task :archive_download, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        Opendata::ResourceDownloadHistoryArchiveJob.bind(site_id: site.id).perform_now
      end
    end

    task :archive_preview, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        Opendata::ResourcePreviewHistoryArchiveJob.bind(site_id: site.id).perform_now
      end
    end

    task :archive_all_download, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        ::Tasks::Opendata.archive_all_download_history(site)
      end
    end

    task :archive_all_preview, [:site] => :environment do |_task, args|
      ::Tasks::Cms.with_site(args[:site] || ENV['site']) do |site|
        ::Tasks::Opendata.archive_all_preview_history(site)
      end
    end
  end
end
