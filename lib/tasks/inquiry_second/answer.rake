namespace :inquiry_second do
  task pull_answers: :environment do
    sync = SS::PullSync.new(InquirySecond::Answer)
    sync.pull_all_and_delete
  end
end
