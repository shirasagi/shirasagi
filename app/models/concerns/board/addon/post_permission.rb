module Board::Addon
  module PostPermission
    extend ActiveSupport::Concern
    extend SS::Addon

    def allowed?(action, user, opts = {})
      site = opts[:site] || @cur_site
      user.cms_user.cms_role_permit_any?(site, "#{action}_board_posts")
    end

    module ClassMethods
      def allow(action, user, opts = {})
        user = user.cms_user
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
