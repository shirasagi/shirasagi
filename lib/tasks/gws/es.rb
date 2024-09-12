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
            feed_all_monitors feed_all_reports feed_all_workflows feed_all_workflows2 feed_all_files
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
          job = ::Gws::Elasticsearch::Indexer::MemoMessageJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::BoardTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::FaqTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::QnaTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::SurveyFormJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::CircularPostJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::MonitorTopicJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::ReportFileJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::WorkflowFileJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)

          puts 'gws/workflow/form'
          job = ::Gws::Elasticsearch::Indexer::WorkflowFormJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
        end
      end

      def feed_all_workflows2
        ::Tasks::Gws::Base.with_site(ENV['site']) do |site|
          if !site.menu_elasticsearch_visible?
            puts 'elasticsearch was not enabled'
            break
          end

          if site.elasticsearch_client.nil?
            puts 'elasticsearch was not configured'
            break
          end

          puts 'gws/workflow2/file'
          job = ::Gws::Elasticsearch::Indexer::Workflow2FileJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
          job = ::Gws::Elasticsearch::Indexer::ShareFileJob.bind(site_id: site)
          job.perform_now(action: 'index', id: :all)
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
      #    job = ::Gws::Elasticsearch::Indexer::WorkloadWorkJob.bind(site_id: site)
      #    job.perform_now(action: 'index', id: :all)
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
