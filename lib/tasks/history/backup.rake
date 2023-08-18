namespace :history do
  namespace :backup do
    task sweep: :environment do
      puts "delete history backups"
      History::Backup::SweepJob.perform_now
    end
  end
end
