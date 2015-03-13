namespace :cms do
  task :check_links => :environment do
    Cms::Task.check_links site: ENV["site"], node: ENV["node"]
  end
end
