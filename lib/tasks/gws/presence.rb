module Tasks
  module Gws
    class Presence
      extend Tasks::Gws::Base

      class << self
        def reset
          each_sites do |site|
            job_class = Gws::Presence::ResetJob.bind(site_id: site.id)
            job_class.perform_now
          end
        end
      end
    end
  end
end
