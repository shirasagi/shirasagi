module Tasks
  module Gws
    class Monitor
      extend Tasks::Gws::Base

      class << self
        def deletion
          opts = {}
          each_sites do |site|
            Rails.logger.info "#{site.name}の照会・回答削除開始。"
            ::Gws::Monitor::DeleteJob.bind(site_id: site.id).perform_now(opts)
          end
        end
      end
    end
  end
end
