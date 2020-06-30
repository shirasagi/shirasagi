namespace :gws do
  namespace :es do
    task ping: :environment do
      ::Tasks::Gws::Es.ping
    end

    task info: :environment do
      ::Tasks::Gws::Es.info
    end

    task list_indexes: :environment do
      ::Tasks::Gws::Es.list_indexes
    end

    task list_types: :environment do
      ::Tasks::Gws::Es.list_types
    end

    task drop: :environment do
      ::Tasks::Gws::Es.drop
    end

    task create_indexes: :environment do
      ::Tasks::Gws::Es.create_indexes
    end

    task feed_all: :environment do
      ::Tasks::Gws::Es.feed_all
    end

    task feed_all_memos: :environment do
      ::Tasks::Gws::Es.feed_all_memos
    end

    task feed_all_boards: :environment do
      ::Tasks::Gws::Es.feed_all_boards
    end

    task feed_all_faqs: :environment do
      ::Tasks::Gws::Es.feed_all_faqs
    end

    task feed_all_qnas: :environment do
      ::Tasks::Gws::Es.feed_all_qnas
    end

    task feed_all_circulars: :environment do
      ::Tasks::Gws::Es.feed_all_circulars
    end

    task feed_all_monitors: :environment do
      ::Tasks::Gws::Es.feed_all_monitors
    end

    task feed_all_reports: :environment do
      ::Tasks::Gws::Es.feed_all_reports
    end

    task feed_all_workflows: :environment do
      ::Tasks::Gws::Es.feed_all_workflows
    end

    task feed_all_files: :environment do
      ::Tasks::Gws::Es.feed_all_files
    end

    namespace :ingest do
      task drop: :environment do
        ::Tasks::Gws::Es::Ingest.drop
      end

      task init: :environment do
        ::Tasks::Gws::Es::Ingest.init
      end

      task info: :environment do
        ::Tasks::Gws::Es::Ingest.info
      end
    end
  end
end
