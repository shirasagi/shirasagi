namespace :ezine do
  task deliver: :environment do
    ::Tasks::Ezine.deliver
  end
end
