namespace :gws do
  task reload_site_usage: :environment do
    puts "# reload site usage"
    ::Tasks::Gws::Base.each_sites do |site|
      next if Gws::Role.site(site).empty?

      puts site.name
      site.reload_usage!
    end
  end
end
