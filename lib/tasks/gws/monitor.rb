module Tasks
  module Gws
    class Monitor
      class << self
        def deletion
          opts = {}
          each_sites do |site|
            Rails.logger.info "#{site.name}の照会・回答削除開始。"
            ::Gws::Monitor::DeleteJob.bind(site_id: site.id).perform_now(opts)
          end
        end

        private

        def each_sites
          name = ENV['site']
          if !name
            puts "site must be specified"
            return
          end

          ::Gws::Group.where(name: name).each do |site|
            yield site
          end
        end
      end
    end
  end
end
