namespace :mail_page do
  task :import => :environment do
    puts "Please input site_name: site=[site_name]" or exit if ENV['site'].blank?

    site = Cms::Site.where(host: ENV['site']).first
    puts "Site not found: #{ENV['site']}" or exit unless site

    filename = "#{Time.zone.now.to_i}.eml"
    dir = "#{Rails.root}/private/files/mail_page_files"
    file = "#{dir}/#{filename}"

    Fs.mkdir_p dir
    Fs.binwrite file, STDIN.read

    job = MailPage::ImportJob.bind(site_id: site.id)
    job.perform_now(file)
  end
end
