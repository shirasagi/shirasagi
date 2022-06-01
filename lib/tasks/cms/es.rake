namespace :cms do
  namespace :es do
    es_validator = proc do |site|
      if site.elasticsearch_client.nil?
        puts 'elasticsearch was not configured'
        return false
      end
      true
    end

    task :feed_all, [:site] => :environment do |task, args|
      ::Tasks::Cms::Base.with_site(args[:site] || ENV['site']) do |site|
        break unless es_validator.call(site)

        all_ids = Cms::Page.site(site).and_public.pluck(:id)
        all_ids.each_slice(100) do |ids|
          pages = Cms::Page.in(id: ids).to_a
          pages.each do |page|
            next unless page.public_node?

            puts "- #{page.filename}"
            next if site.elasticsearch_deny.include?(page.filename)
            job = ::Cms::Elasticsearch::Indexer::PageReleaseJob.bind(site_id: site)
            job.perform_now(action: 'index', id: page.id.to_s)
          end
        end

        ::Cms::PageIndexQueue.site(site).where(action: 'release').destroy_all
      end
    end

    task :feed_releases, [:site] => :environment do |task, args|
      ::Tasks::Cms::Base.with_site(args[:site] || ENV['site']) do |site|
        break unless es_validator.call(site)
        ::Cms::Elasticsearch::Indexer::FeedReleasesJob.bind(site_id: site).perform_now
      end
    end

    task drop: :environment do
      ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
        break unless es_validator.call(site)
        puts ::Cms::Elasticsearch.drop_index(site: site).to_json
      end
    end

    task create_indexes: :environment do
      ::Tasks::Cms::Base.with_site(ENV['site']) do |site|
        break unless es_validator.call(site)
        puts ::Cms::Elasticsearch.create_index(site: site, synonym: ENV.key?("synonym")).to_json
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
          puts Cms::Elasticsearch.init_ingest(site: site).to_json
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
