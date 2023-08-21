module Tasks
  module Gws
    class Circular
      extend Tasks::Gws::Base

      class << self
        def deletion
          opts = {}
          each_sites do |site|
            Rails.logger.info "#{site.name}の回覧板削除開始。"
            ::Gws::Circular::DeleteJob.bind(site_id: site.id).perform_now(opts)
          end
        end
      end
    end
  end
end
