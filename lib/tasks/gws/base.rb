module Tasks
  module Gws
    module Base
      module_function

      def each_sites
        name = ENV['site']
        if name
          all_ids = ::Gws::Group.all.where(name: name).pluck(:id)
        else
          all_ids = ::Gws::Group.all.where(name: { "$not" => /\// }).pluck(:id)
        end

        all_ids.each_slice(20) do |ids|
          ::Gws::Group.where(:id.in => ids).each do |site|
            yield site
          end
        end
      end

      def with_site(name)
        if name.blank?
          puts "Please input site_name: site=[site_name]"
          return
        end

        site = ::Gws::Group.where(name: name).first
        if !site
          puts "Site not found: #{name}"
          return
        end

        yield site
      end

      def with_user(name)
        if name.blank?
          puts "Please input user name: user=[user_name]"
          return
        end

        user = ::Gws::User.flex_find(name)
        if !user
          puts "User not found: #{name}"
          return
        end

        yield user
      end
    end
  end
end
