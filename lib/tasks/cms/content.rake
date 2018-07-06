namespace :cms do
  def mock_task(attr)
    task = OpenStruct.new(attr)
    def task.log(msg)
      puts(msg)
    end
    task
  end

  task :export_content => :environment do
    puts "Please input site name: site=[site_name]" or exit if ENV['site'].blank?

    site = SS::Site.where(host: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless site

    job = Cms::ContentExportJob.new
    job.task = mock_task(
      site_id: site.id
    )
    job.perform
  end

  task :import_content => :environment do
    puts "Please input site name: site=[site_name]" or exit if ENV['site'].blank?
    puts "Please input import file: site=[site_name]" or exit if ENV['file'].blank?

    site = SS::Site.where(host: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless site

    file = ENV['file']
    puts "File not found: #{ENV['file']}" or exit unless File.exist?(file)

    job = Cms::ContentImportJob.new
    job.task = mock_task(
      site_id: site.id,
      import_file: file
    )
    job.perform
  end
end
