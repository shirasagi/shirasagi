namespace :gws do
  namespace :es do
    task ping: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      if !site.elasticsearch_enabled?
        puts 'elasticsearch was not enabled'
        break
      end

      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        break
      end

      puts site.elasticsearch_client.ping
    end

    task info: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      if !site.elasticsearch_enabled?
        puts 'elasticsearch was not enabled'
        break
      end

      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        break
      end

      puts site.elasticsearch_client.info.to_json
    end

    task drop: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      if !site.elasticsearch_enabled?
        puts 'elasticsearch was not enabled'
        break
      end

      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        break
      end

      puts site.elasticsearch_client.indices.delete(index: "g#{site.id}").to_json
    end

    task create_indexes: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      if !site.elasticsearch_enabled?
        puts 'elasticsearch was not enabled'
        break
      end

      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        break
      end

      settings = ::File.read(Rails.root.join('vendor', 'elasticsearch', 'settings.json'))
      settings = JSON.parse(settings)

      mappings = ::File.read(Rails.root.join('vendor', 'elasticsearch', 'mappings.json'))
      mappings = JSON.parse(mappings)

      puts site.elasticsearch_client.indices.create(index: "g#{site.id}", body: { settings: settings, mappings: mappings}).to_json
    end

    task feed_all: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      if !site.elasticsearch_enabled?
        puts 'elasticsearch was not enabled'
        break
      end

      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        break
      end

      Rake::Task['gws:es:feed_all_boards'].execute
      Rake::Task['gws:es:feed_all_files'].execute
    end

    task feed_all_boards: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      if !site.elasticsearch_enabled?
        puts 'elasticsearch was not enabled'
        break
      end

      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        break
      end

      puts 'gws/board/topic and gws/board/post'
      Gws::Board::Topic.site(site).topic.each do |topic|
        puts "- #{topic.name}"
        job = Gws::Elasticsearch::Indexer::BoardTopicJob.bind(site_id: site)
        job.perform_now(action: 'index', id: topic.id.to_s)
        topic.descendants.each do |post|
          puts "-- #{post.name}"
          job = Gws::Elasticsearch::Indexer::BoardPostJob.bind(site_id: site)
          job.perform_now(action: 'index', id: post.id.to_s)
        end
      end
    end

    task feed_all_files: :environment do
      site = Gws::Group.find_by(name: ENV['site'])
      if !site.elasticsearch_enabled?
        puts 'elasticsearch was not enabled'
        break
      end

      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        break
      end

      puts 'gws/share/file'
      Gws::Share::File.site(site).each do |file|
        puts "- #{file.name}"
        job = Gws::Elasticsearch::Indexer::ShareFileJob.bind(site_id: site)
        job.perform_now(action: 'index', id: file.id.to_s)
      end
    end

    namespace :ingest do
      task drop: :environment do
        site = Gws::Group.find_by(name: ENV['site'])
        if !site.elasticsearch_enabled?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts site.elasticsearch_client.ingest.delete_pipeline(id: 'attachment').to_json
      end

      task init: :environment do
        site = Gws::Group.find_by(name: ENV['site'])
        if !site.elasticsearch_enabled?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        settings = ::File.read(Rails.root.join('vendor', 'elasticsearch', 'ingest_attachment.json'))
        settings = JSON.parse(settings)

        puts site.elasticsearch_client.ingest.put_pipeline(id: 'attachment', body: settings).to_json
      end

      task info: :environment do
        site = Gws::Group.find_by(name: ENV['site'])
        if !site.elasticsearch_enabled?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts site.elasticsearch_client.ingest.get_pipeline(id: 'attachment').to_json
      end
    end
  end
end
