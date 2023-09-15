module Tasks
  module Gws
    module Es
      module_function

      def ping
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

      def info
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

      def list_indexes
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

      def list_types
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

      def drop
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
            puts 'elasticsearch was not enabled'
            break
          end

          if site.elasticsearch_client.nil?
            puts 'elasticsearch was not configured'
            break
          end

          puts ::Gws::Elasticsearch.drop_index(site: site).to_json
        end
      end

      def create_indexes
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
            puts 'elasticsearch was not enabled'
            break
          end

          if site.elasticsearch_client.nil?
            puts 'elasticsearch was not configured'
            break
          end

          puts ::Gws::Elasticsearch.create_index(site: site, synonym: ENV.key?("synonym")).to_json
        end
      end

      def feed_all
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
            puts 'elasticsearch was not enabled'
            break
          end

          if site.elasticsearch_client.nil?
            puts 'elasticsearch was not configured'
            break
          end

          %i[
            feed_all_memos feed_all_boards feed_all_faqs feed_all_qnas feed_all_surveys feed_all_circulars
            feed_all_monitors feed_all_reports feed_all_workflows feed_all_files
          ].each do |method|
            ::Tasks::Gws::Es.send(method)
          end
        end
      end

      def feed_all_memos
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

      def feed_all_boards
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
          ::Tasks::Gws::Base.each_item(::Gws::Board::Topic.site(site).topic.without_deleted) do |topic|
            puts "- #{topic.name}"
            job = ::Gws::Elasticsearch::Indexer::BoardTopicJob.bind(site_id: site)
            job.perform_now(action: 'index', id: topic.id.to_s)
            ::Tasks::Gws::Base.each_item(topic.descendants.without_deleted) do |post|
              puts "-- #{post.name}"
              job = ::Gws::Elasticsearch::Indexer::BoardPostJob.bind(site_id: site)
              job.perform_now(action: 'index', id: post.id.to_s)
            end
          end
        end
      end

      def feed_all_faqs
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
          ::Tasks::Gws::Base.each_item(::Gws::Faq::Topic.site(site).topic.without_deleted) do |topic|
            puts "- #{topic.name}"
            job = ::Gws::Elasticsearch::Indexer::FaqTopicJob.bind(site_id: site)
            job.perform_now(action: 'index', id: topic.id.to_s)
            ::Tasks::Gws::Base.each_item(topic.descendants.without_deleted) do |post|
              puts "-- #{post.name}"
              job = ::Gws::Elasticsearch::Indexer::FaqPostJob.bind(site_id: site)
              job.perform_now(action: 'index', id: post.id.to_s)
            end
          end
        end
      end

      def feed_all_qnas
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
          ::Tasks::Gws::Base.each_item(::Gws::Qna::Topic.site(site).topic.without_deleted) do |topic|
            puts "- #{topic.name}"
            job = ::Gws::Elasticsearch::Indexer::QnaTopicJob.bind(site_id: site)
            job.perform_now(action: 'index', id: topic.id.to_s)
            ::Tasks::Gws::Base.each_item(topic.descendants.without_deleted) do |post|
              puts "-- #{post.name}"
              job = ::Gws::Elasticsearch::Indexer::QnaPostJob.bind(site_id: site)
              job.perform_now(action: 'index', id: post.id.to_s)
            end
          end
        end
      end

      def feed_all_surveys
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
            puts 'elasticsearch was not enabled'
            break
          end

          if site.elasticsearch_client.nil?
            puts 'elasticsearch was not configured'
            break
          end

          puts 'gws/survey/form'
          ::Tasks::Gws::Base.each_item(::Gws::Survey::Form.site(site)) do |form|
            puts "- #{form.name}"
            job = ::Gws::Elasticsearch::Indexer::SurveyFormJob.bind(site_id: site)
            job.perform_now(action: 'index', id: form.id.to_s)
          end
        end
      end

      def feed_all_circulars
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
          ::Tasks::Gws::Base.each_item(::Gws::Circular::Post.site(site).topic.without_deleted) do |post|
            puts "- #{post.name}"
            job = ::Gws::Elasticsearch::Indexer::CircularPostJob.bind(site_id: site)
            job.perform_now(action: 'index', id: post.id.to_s)
            ::Tasks::Gws::Base.each_item(post.comments.without_deleted) do |comment|
              puts "-- #{comment.name}"
              job = ::Gws::Elasticsearch::Indexer::CircularCommentJob.bind(site_id: site)
              job.perform_now(action: 'index', id: comment.id.to_s)
            end
          end
        end
      end

      def feed_all_monitors
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
            puts 'elasticsearch was not enabled'
            break
          end

          if site.elasticsearch_client.nil?
            puts 'elasticsearch was not configured'
            break
          end

          puts 'gws/monitor/topic and gws/monitor/post'
          ::Tasks::Gws::Base.each_item(::Gws::Monitor::Topic.site(site).topic.without_deleted) do |topic|
            puts "- #{topic.name}"
            job = ::Gws::Elasticsearch::Indexer::MonitorTopicJob.bind(site_id: site)
            job.perform_now(action: 'index', id: topic.id.to_s)
            ::Tasks::Gws::Base.each_item(topic.descendants.without_deleted) do |post|
              puts "-- #{post.name}"
              job = ::Gws::Elasticsearch::Indexer::MonitorPostJob.bind(site_id: site)
              job.perform_now(action: 'index', id: post.id.to_s)
            end
          end
        end
      end

      def feed_all_reports
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
          ::Tasks::Gws::Base.each_item(::Gws::Report::File.site(site).without_deleted) do |file|
            puts "- #{file.name}"
            job = ::Gws::Elasticsearch::Indexer::ReportFileJob.bind(site_id: site)
            job.perform_now(action: 'index', id: file.id.to_s)
          end
        end
      end

      def feed_all_workflows
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
          ::Tasks::Gws::Base.each_item(::Gws::Workflow::File.site(site).without_deleted) do |file|
            puts "- #{file.name}"
            job = ::Gws::Elasticsearch::Indexer::WorkflowFileJob.bind(site_id: site)
            job.perform_now(action: 'index', id: file.id.to_s)
          end

          puts 'gws/workflow/form'
          ::Tasks::Gws::Base.each_item(::Gws::Workflow::Form.site(site)) do |file|
            puts "- #{file.name}"
            job = ::Gws::Elasticsearch::Indexer::WorkflowFormJob.bind(site_id: site)
            job.perform_now(action: 'index', id: file.id.to_s)
          end
        end
      end

      def feed_all_files
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
          ::Tasks::Gws::Base.each_item(::Gws::Share::File.site(site).without_deleted) do |file|
            puts "- #{file.name}"
            job = ::Gws::Elasticsearch::Indexer::ShareFileJob.bind(site_id: site)
            job.perform_now(action: 'index', id: file.id.to_s)
          end
        end
      end

      #def feed_all_workloads
      #  ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
      #    if !site.menu_elasticsearch_visible?
      #      puts 'elasticsearch was not enabled'
      #      break
      #    end
      #
      #    if site.elasticsearch_client.nil?
      #      puts 'elasticsearch was not configured'
      #      break
      #    end
      #
      #    puts 'gws/workload/work'
      #    ::Tasks::Gws::Base.each_item(::Gws::Workload::Work.site(site).without_deleted) do |work|
      #      puts "- #{work.name}"
      #      job = ::Gws::Elasticsearch::Indexer::WorkloadWorkJob.bind(site_id: site)
      #      job.perform_now(action: 'index', id: work.id.to_s)
      #    end
      #  end
      #end

      module Ingest
        module_function

        def drop
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

        def init
          ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
            if !site.menu_elasticsearch_visible?
              puts 'elasticsearch was not enabled'
              break
            end

            if site.elasticsearch_client.nil?
              puts 'elasticsearch was not configured'
              break
            end

            puts ::Gws::Elasticsearch.init_ingest(site: site).to_json
          end
        end

        def info
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
end
