module Tasks
  module Cms
    module Base
      module_function

      def with_site(name)
        if name.blank?
          puts "Please input site_name: site=[site_name]"
          return
        end

        site = ::Cms::Site.where(host: name).first
        if !site
          puts "Site not found: #{name}"
          return
        end

        yield site
      end
    end
  end
end
