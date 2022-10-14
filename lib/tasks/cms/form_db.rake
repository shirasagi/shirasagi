namespace :cms do
  namespace :form_db do
    task import: :environment do
      puts "# form_db: import from url"

      job = Cms::FormDb::ImportUrlsJob.bind({})
      job.perform_now
    end

    task import_later: :environment do
      puts "# form_db: import from url"

      job = Cms::FormDb::ImportUrlsJob.bind({})
      job.perform_later
    end
  end
end
