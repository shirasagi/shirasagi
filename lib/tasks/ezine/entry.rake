namespace :ezine do
  task pull_from_public: :environment do
    ::Ezine::Entry.pull_from_public!
  end
end
