namespace :mail_page do
  task import: :environment do
    ::Tasks::Cms.with_site(ENV['site']) do |site|
      filename = "#{Time.zone.now.to_i}.eml"
      dir = "#{Rails.root}/private/files/mail_page_files"
      file = "#{dir}/#{filename}"

      Fs.mkdir_p dir
      Fs.binwrite file, STDIN.read

      job = MailPage::ImportJob.bind(site_id: site.id)
      job.perform_now(file)
    end
  end
end
