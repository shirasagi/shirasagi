namespace :history do
  namespace :backup do
    task sweep: :environment do
      History::Backup::SweepJob.perform_now
    end
  end
end
