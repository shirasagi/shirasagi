namespace :cms do
  namespace :es do
    es_validator = proc do |site|
      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        return false
      end
      true
    end

    task feed_all: :environment do
      ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
        break unless es_validator.call(site)

        pages = Cms::Page.site(site).and_public
        pages.each do |page|
          puts "- #{page.filename}"
          next if site.elasticsearch_deny.include?(page.filename)
          job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
          job.perform_now(action: 'index', id: page.id.to_s)
        end

        Cms::PageIndexQueue.site(site).where(action: 'release').destroy_all
      end
    end

    task feed_releases: :environment do
      ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
        break unless es_validator.call(site)

        ids = Cms::PageIndexQueue.site(site).order_by(created: -1).pluck(:id)
        del = []

        ids.each do |id|
          next if del.include?(id)
          item = Cms::PageIndexQueue.where(id: id).first
          next unless item

          puts "- #{item.filename}"
          if site.elasticsearch_deny.include?(item.filename)
            item.destroy
            next
          end

          del += item.old_queues.pluck(:id)
          item.old_queues.destroy_all

          job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
          job.perform_now(action: item.job_action, id: item.page_id.to_s, queue_id: item.id.to_s)
        end
      end
    end

    task drop: :environment do
      ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
        break unless es_validator.call(site)

        puts site.elasticsearch_client.indices.delete(index: "s#{site.id}").to_json
      end
    end

    task create_indexes: :environment do
      ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
        break unless es_validator.call(site)

        settings = ::File.read(Rails.root.join('vendor', 'elasticsearch', 'settings.json'))
        settings = JSON.parse(settings)

        if ENV['synonym']
          settings["analysis"]["analyzer"]["my_ja_analyzer"]["filter"].push("synonym")
          settings["analysis"]["filter"]["synonym"] = {
            "type": "synonym",
            "synonyms_path": "/etc/elasticsearch/synonym.txt"
          }
        end

        mappings = ::File.read(Rails.root.join('vendor', 'elasticsearch', 'mappings.json'))
        mappings = JSON.parse(mappings)

        body = { settings: settings, mappings: mappings }
        puts site.elasticsearch_client.indices.create(index: "s#{site.id}", body: body).to_json
      end
    end

    namespace :ingest do
      task drop: :environment do
        ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
          break unless es_validator.call(site)

          puts site.elasticsearch_client.ingest.delete_pipeline(id: 'attachment').to_json
        end
      end

      task init: :environment do
        ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
          break unless es_validator.call(site)

          settings = ::File.read(Rails.root.join('vendor', 'elasticsearch', 'ingest_attachment.json'))
          settings = JSON.parse(settings)

          puts site.elasticsearch_client.ingest.put_pipeline(id: 'attachment', body: settings).to_json
        end
      end

      task info: :environment do
        ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
          break unless es_validator.call(site)

          puts site.elasticsearch_client.ingest.get_pipeline(id: 'attachment').to_json
        end
      end
    end
  end
end
