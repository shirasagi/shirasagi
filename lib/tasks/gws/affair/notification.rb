module Tasks
  module Gws
    module Affair
      class Notification
        extend Tasks::Gws::Base

        class << self
          def deliver
            each_sites do |site|
              puts site.name
              ::Gws::Affair::NotifyCompensatoryFileJob.bind(site_id: site.id).perform_now
            end
          end
        end
      end
    end
  end
end
