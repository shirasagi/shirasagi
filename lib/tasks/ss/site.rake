namespace :ss do
  task :create_site => :environment do
    item = SS::Site.create eval(ENV["data"])
    puts item.errors.empty? ? "  created  #{item.name}" : item.errors.full_messages.join("\n  ")
  end
end
