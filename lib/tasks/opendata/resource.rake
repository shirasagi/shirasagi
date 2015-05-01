namespace :opendata do
  task :export_resources => :environment do
    Opendata::Dataset.each do |dataset|
      next if dataset.resources.size == 0
      puts dataset.name
      dataset.resources.each do |resource|
        next unless resource.file
        puts "  #{resource.filename}"
        begin
          Fs.binwrite resource.path, resource.file.data
        rescue => e
          puts "Error: #{e}"
        end
      end
    end
  end

  task :fuseki_import => :environment do
    Opendata::Dataset.each do |dataset|
      next if dataset.resources.size == 0
      puts dataset.name
      dataset.resources.each do |resource|
        next unless resource.file
        puts "  #{resource.filename}"
        begin
          resource.save_rdf_store
        rescue => e
          puts "Error: #{e}"
        end
      end
    end
  end

  task :fuseki_clear => :environment do
    Opendata::Sparql.clear_all
  end

  task :crawl => :environment do
    site = SS::Site.where(host: ENV["site"]).first
    datasets = Opendata::Dataset.site(site)
    datasets.each do |ds|
      next if ds.url_resources.blank?
      ds.url_resources.each do |ur|
        ur.do_crawl
      end
    end
  end
end
