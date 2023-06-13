namespace :mail_page do
  task import: :environment do
    ::Tasks::Cms.with_site(ENV['site']) do |site|
      file = SS::MailHandler.write_eml(STDIN.read, "mail_page")
      job = MailPage::ImportJob.bind(site_id: site.id)
      job.perform_now(file)
    end
  end
end
