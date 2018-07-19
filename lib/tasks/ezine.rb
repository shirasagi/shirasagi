module Tasks
  class Ezine
    class << self
      def deliver
        ::Tasks::Cms.each_sites do |site|
          puts site.name
          ::Tasks::Cms.perform_job(::Ezine::DeliverReservedJob, site: site)
        end
      end
    end
  end
end
