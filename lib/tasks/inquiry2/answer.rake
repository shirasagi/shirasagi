namespace :inquiry2 do
  task pull_answers: :environment do
    sync = SS::PullSync.new(Inquiry2::Answer)
    sync.pull_all_and_delete
  end
end
