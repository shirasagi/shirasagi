namespace :ezine do
  task :pull_from_public => :environment do
    Ezine::Member.pull_from_public!
  end
end
