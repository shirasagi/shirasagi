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
          resource.save_fuseki_rdf
        rescue => e
          puts "Error: #{e}"
        end
      end
    end
  end

  task :fuseki_clear => :environment do
    Opendata::Sparql.clear_all
  end
end
