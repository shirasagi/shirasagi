namespace :opendata do
  task update_resource_histories: :environment do
    Opendata::ResourceDownloadHistory.update_histories
    Opendata::ResourceDatasetDownloadHistory.update_histories
    Opendata::ResourceBulkDownloadHistory.update_histories
    Opendata::ResourcePreviewHistory.update_histories
  end

  task fuseki_import: :environment do
    Opendata::Dataset.each do |dataset|
      next if dataset.resources.blank?
      puts dataset.name
      dataset.resources.each do |resource|
        next unless resource.file
        puts "  #{resource.filename}"
        begin
          resource.state_changed
        rescue => e
          puts "Error: #{e}"
        end
      end
    end
  end

  task fuseki_clear: :environment do
    Opendata::Sparql.clear_all
  end

  task crawl: :environment do
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
