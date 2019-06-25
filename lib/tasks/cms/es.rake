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
      end
    end

    task feed_releases: :environment do
      ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
        break unless es_validator.call(site)

        items = Cms::PageRelease.site(site).active.unindexed.order_by(created: 1)
        items.each do |item|
          puts "- #{item.filename}"
          next if site.elasticsearch_deny.include?(item.filename)
          job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
          job.perform_now(action: 'index', id: item.page_id.to_s, release_id: item.id.to_s)
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

        mappings = ::File.read(Rails.root.join('vendor', 'elasticsearch', 'mappings.json'))
        mappings = JSON.parse(mappings)

        puts site.elasticsearch_client.indices.create(index: "s#{site.id}", body: { settings: settings, mappings: mappings}).to_json
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
