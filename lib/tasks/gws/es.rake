namespace :gws do
  namespace :es do
    task ping: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts site.elasticsearch_client.ping
      end
    end

    task info: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts site.elasticsearch_client.info.to_json
      end
    end

    task list_indexes: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts site.elasticsearch_client.cat.indices
      end
    end

    task list_types: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        index_name = "g#{site.id}"
        puts site.elasticsearch_client.indices.get(index: index_name)[index_name]['mappings'].keys
      end
    end

    task drop: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts site.elasticsearch_client.indices.delete(index: "g#{site.id}").to_json
      end
    end

    task create_indexes: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
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
    end

    task feed_all: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        Rake::Task['gws:es:feed_all_memos'].execute
        Rake::Task['gws:es:feed_all_boards'].execute
        Rake::Task['gws:es:feed_all_faqs'].execute
        Rake::Task['gws:es:feed_all_qnas'].execute
        Rake::Task['gws:es:feed_all_circulars'].execute
        Rake::Task['gws:es:feed_all_monitors'].execute
        Rake::Task['gws:es:feed_all_reports'].execute
        Rake::Task['gws:es:feed_all_workflows'].execute
        Rake::Task['gws:es:feed_all_files'].execute
      end
    end

    task feed_all_memos: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/memo/message'
        ::Tasks::Gws::Base.each_item(::Gws::Memo::Message.site(site)) do |message|
          puts "- #{message.subject}"
          job = ::Gws::Elasticsearch::Indexer::MemoMessageJob.bind(site_id: site)
          job.perform_now(action: 'index', id: message.id.to_s)
        end
      end
    end

    task feed_all_boards: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/board/topic and gws/board/post'
        ::Tasks::Gws::Base.each_item(::Gws::Board::Topic.site(site).topic) do |topic|
          puts "- #{topic.name}"
          job = ::Gws::Elasticsearch::Indexer::BoardTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: topic.id.to_s)
          ::Tasks::Gws::Base.each_item(topic.descendants) do |post|
            puts "-- #{post.name}"
            job = ::Gws::Elasticsearch::Indexer::BoardPostJob.bind(site_id: site)
            job.perform_now(action: 'index', id: post.id.to_s)
          end
        end
      end
    end

    task feed_all_faqs: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/faq/topic and gws/faq/post'
        ::Tasks::Gws::Base.each_item(::Gws::Faq::Topic.site(site).topic) do |topic|
          puts "- #{topic.name}"
          job = ::Gws::Elasticsearch::Indexer::FaqTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: topic.id.to_s)
          ::Tasks::Gws::Base.each_item(topic.descendants) do |post|
            puts "-- #{post.name}"
            job = ::Gws::Elasticsearch::Indexer::FaqPostJob.bind(site_id: site)
            job.perform_now(action: 'index', id: post.id.to_s)
          end
        end
      end
    end

    task feed_all_qnas: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/qna/topic and gws/qna/post'
        ::Tasks::Gws::Base.each_item(::Gws::Qna::Topic.site(site).topic) do |topic|
          puts "- #{topic.name}"
          job = ::Gws::Elasticsearch::Indexer::QnaTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: topic.id.to_s)
          ::Tasks::Gws::Base.each_item(topic.descendants) do |post|
            puts "-- #{post.name}"
            job = ::Gws::Elasticsearch::Indexer::QnaPostJob.bind(site_id: site)
            job.perform_now(action: 'index', id: post.id.to_s)
          end
        end
      end
    end

    task feed_all_circulars: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/circular/post and gws/circular/comment'
        ::Tasks::Gws::Base.each_item(::Gws::Circular::Post.site(site).topic) do |post|
          puts "- #{post.name}"
          job = ::Gws::Elasticsearch::Indexer::CircularPostJob.bind(site_id: site)
          job.perform_now(action: 'index', id: post.id.to_s)
          ::Tasks::Gws::Base.each_item(post.comments) do |comment|
            puts "-- #{comment.name}"
            job = ::Gws::Elasticsearch::Indexer::CircularCommentJob.bind(site_id: site)
            job.perform_now(action: 'index', id: comment.id.to_s)
          end
        end
      end
    end

    task feed_all_monitors: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/qna/topic and gws/qna/post'
        ::Tasks::Gws::Base.each_item(::Gws::Monitor::Topic.site(site).topic) do |topic|
          puts "- #{topic.name}"
          job = ::Gws::Elasticsearch::Indexer::MonitorTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: topic.id.to_s)
          ::Tasks::Gws::Base.each_item(topic.descendants) do |post|
            puts "-- #{post.name}"
            job = ::Gws::Elasticsearch::Indexer::MonitorPostJob.bind(site_id: site)
            job.perform_now(action: 'index', id: post.id.to_s)
          end
        end
      end
    end

    task feed_all_reports: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/report/file'
        ::Tasks::Gws::Base.each_item(::Gws::Report::File.site(site)) do |file|
          puts "- #{file.name}"
          job = ::Gws::Elasticsearch::Indexer::ReportFileJob.bind(site_id: site)
          job.perform_now(action: 'index', id: file.id.to_s)
        end
      end
    end

    task feed_all_workflows: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/workflow/file'
        ::Tasks::Gws::Base.each_item(::Gws::Workflow::File.site(site)) do |file|
          puts "- #{file.name}"
          job = ::Gws::Elasticsearch::Indexer::WorkflowFileJob.bind(site_id: site)
          job.perform_now(action: 'index', id: file.id.to_s)
        end
      end
    end

    task feed_all_files: :environment do
      ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
        if !site.menu_elasticsearch_visible?
          puts 'elasticsearch was not enabled'
          break
        end

        if site.elasticsearch_client.nil?
          puts 'elasticsearch was not configured'
          break
        end

        puts 'gws/share/file'
        ::Tasks::Gws::Base.each_item(::Gws::Share::File.site(site)) do |file|
          puts "- #{file.name}"
          job = ::Gws::Elasticsearch::Indexer::ShareFileJob.bind(site_id: site)
          job.perform_now(action: 'index', id: file.id.to_s)
        end
      end
    end

    namespace :ingest do
      task drop: :environment do
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
            puts 'elasticsearch was not enabled'
            break
          end

          if site.elasticsearch_client.nil?
            puts 'elasticsearch was not configured'
            break
          end

          puts site.elasticsearch_client.ingest.delete_pipeline(id: 'attachment').to_json
        end
      end

      task init: :environment do
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
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
      end

      task info: :environment do
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
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
end
