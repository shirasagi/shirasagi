module Tasks
  module Gws
    class Workflow2
      extend Tasks::Gws::Base

      class << self
        # ワークフローの承認ルート設定をワークフロー2へ移行（コピー）するタスク
        def migrate_route
          each_sites do |site|
            puts "# #{site.name}"
            job_class = ::Gws::Workflow2::RouteMigrationJob.bind(site_id: site.id)
            job_class.perform_now
          end
        end
      end
    end
  end
end
