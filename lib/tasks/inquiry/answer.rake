namespace :inquiry do
  task :pull_answers => :environment do
    sync = SS::PullSync.new(Inquiry::Answer)
    sync.pull_all_and_delete
  end
end
