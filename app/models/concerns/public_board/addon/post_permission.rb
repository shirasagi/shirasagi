module PublicBoard::Addon
  module PostPermission
    extend ActiveSupport::Concern
    extend SS::Addon

    public
      def allowed?(action, user, opts = {})
        site = opts[:site] || @cur_site
        #node = opts[:node] || @cur_node

        permit = "#{action}_board_posts"

        if user.cms_role_permissions["#{permit}_#{site.id}"].to_i > 0
          return true
        else
          return false
        end
      end

    module ClassMethods
      public
        def allow(action, user, opts = {})
          site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
          permit = "#{action}_board_posts"

          if user.cms_roles.where(site_id: site_id).in(permissions: permit).first
            self.all
          else
            self.none
          end
        end

        def allowed?(action, user, opts = {})
          self.new.allowed?(action, user, opts)
        end
    end
  end
end
