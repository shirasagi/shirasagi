namespace :recommend do
  task pull_history_logs: :environment do
    sync = SS::PullSync.new(Recommend::History::Log)
    sync.pull_all_and_delete
  end
end
