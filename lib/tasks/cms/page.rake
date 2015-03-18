namespace :cms do
  task :generate_nodes => :environment do
    Cms::Task.generate_nodes site: ENV["site"], node: ENV["node"], limit: ENV["limit"]
  end

  task :generate_pages => :environment do
    Cms::Task.generate_pages site: ENV["site"], node: ENV["node"]
  end

  task :update_pages => :environment do
    Cms::Task.update_pages site: ENV["site"], node: ENV["node"]
  end

  task :release_pages => :environment do
    Cms::Task.release_pages site: ENV["site"]
  end

  task :remove_pages => :environment do
    Cms::Task.remove_pages site: ENV["site"]
  end

  task :check_links => :environment do
    Cms::Task.check_links site: ENV["site"], node: ENV["node"], email: ENV["email"]
  end
end
