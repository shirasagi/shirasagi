module Tasks
  class Ezine
    class << self
      def deliver
        with_site(::Ezine::DeliverReservedJob)
      end

      private

      def find_sites(site)
        return ::Cms::Site unless site
        ::Cms::Site.where host: site
      end

      def with_site(job_class, opts = {})
        find_sites(ENV["site"]).each do |site|
          job = job_class.bind(site_id: site)
          job.perform_now(opts)
        end
      end
    end
  end
end
