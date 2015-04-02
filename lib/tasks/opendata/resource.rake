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

  task :crawling => :environment do
    require "open-uri"
    require "timeout"

    site = SS::Site.where(host: ENV["site"]).first
    datasets = Opendata::Dataset.site(site)
    datasets.each do |ds|
      next if ds.url_resources.size == 0
      ds.url_resources.each do |ur|
        begin
          time_out = 30
          timeout(time_out){
            url_file = open(ur.original_url)
            puts ur.original_url
            if ur.crawl_update == "none"
              if url_file.present?
                if url_file.last_modified.present?
                  if ur.original_updated == nil
                    ur.crawl_state = "updated"
                  elsif url_file.last_modified > ur.original_updated.beginning_of_day
                    ur.crawl_state = "updated"
                  elsif url_file.last_modified <= ur.original_updated.beginning_of_day
                    ur.crawl_state = "same"
                  end
                  ur.original_updated = url_file.last_modified
                else
                  puts "no last_modified"
                  ur.crawl_state = "deleted"
                end
              else
                puts "no file"
                ur.crawl_state = "deleted"
              end
              res = ur.save(validate: false)
              if res == true
                puts "success"
              else
                puts "failure"
              end
            elsif ur.crawl_update == "auto"
              if url_file.present?
                if url_file.last_modified.present?
                  if url_file.last_modified > ur.original_updated.beginning_of_day
                    ur.crawl_state = "same"
                    ur.save
                  end
                end
              end
            end
          }
        rescue TimeoutError
          puts I18n.t("opendata.errors.messages.invalid_timeout")
          next
        rescue => e
          puts "Error: #{e}"
          next
        end
      end
    end
  end
end
