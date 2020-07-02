module Tasks
  module Gws
    module Base
      module_function

      def each_item(criteria)
        all_ids = criteria.pluck(:id)
        all_ids.each_slice(20) do |ids|
          criteria.in(id: ids).to_a.each do |item|
            yield item
          end
        end
      end

      def each_sites
        name = ENV['site']
        if name
          criteria = ::Gws::Group.all.where(name: name)
        else
          criteria = ::Gws::Group.all.where(name: { "$not" => /\// })
        end

        ::Tasks::Gws::Base.each_item(criteria) do |site|
          yield site
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
