namespace :ss do
  task create_site: :environment do
    item = Cms::Site.create eval(ENV["data"])
    puts item.errors.empty? ? "  created  #{item.name}" : item.errors.full_messages.join("\n  ")
  end

  task remove_site: :environment do
    ::Tasks::Cms.with_site(ENV['site']) do |site|
      ::SS::RemoveSiteJob.perform_now(site.id)
    end
  end
end
