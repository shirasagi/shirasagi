namespace :translate do
  task remove_text_caches: :environment do
    ::Tasks::Cms.each_sites do |site|
      puts "# #{site.name}"
      items = Translate::TextCache.site(site)
      items.destroy_all
      puts "destroy text_caches"
    end
  end

  task :reset_api_count, [:site] => :environment do |task, args|
    ::Tasks::Cms.each_sites do |site|
      puts "# #{site.name}"
      site.reset_translate_api_count!
      puts "reset translate api count"
    end
  end
end
