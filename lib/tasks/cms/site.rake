namespace :cms do
  def mock_task(attr)
    task = OpenStruct.new(attr)
    def task.log(msg); puts(msg); end
    task
  end

  task :export_site => :environment do
    puts "Please input site name: site=[site_name]" or exit if ENV['site'].blank?

    site = SS::Site.where(host: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless site

    job = Sys::SiteExportJob.new
    job.task = mock_task(
      source_site_id: site.id
    )
    job.perform
  end

  task :import_site => :environment do
    puts "Please input site name: site=[site_name]" or exit if ENV['site'].blank?
    puts "Please input import file: site=[site_name]" or exit if ENV['file'].blank?

    site = SS::Site.where(host: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless site

    file = ENV['file']
    puts "File not found: #{ENV['file']}" or exit unless File.exist?(file)

    job = Sys::SiteImportJob.new
    job.task = mock_task(
      target_site_id: site.id,
      import_file: file
    )
    job.perform
  end
end
