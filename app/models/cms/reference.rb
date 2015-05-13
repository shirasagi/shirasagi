module Cms::Reference
  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :cms_roles, class_name: "Cms::Role"
      permit_params cms_role_ids: []
    end

    public
      def cms_role_level(site)
        cms_roles.site(site).pluck(:permission_level).max
      end

      def cms_role_permissions
        return @cms_role_permissions if @cms_role_permissions

        @cms_role_permissions ||= {}
        cms_roles.each do |role|
          role.permissions.each do |name|
            key = "#{name}_#{role.site_id}"
            if level = @cms_role_permissions[key]
              @cms_role_permissions[key] = [level, role.permission_level].max
            else
              @cms_role_permissions[key] = role.permission_level
            end
          end
        end
        @cms_role_permissions
      end
  end

  module Layout
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      belongs_to :layout, class_name: "Cms::Layout"
      permit_params :layout_id
    end
  end

  module PageLayout
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      belongs_to :page_layout, class_name: "Cms::Layout"
      permit_params :page_layout_id
    end
  end

  module StCategory
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Category::Node::Base"
      permit_params category_ids: []

      public
        def st_parent_categories
          categories = []
          parents = st_categories.sort_by { |cate| cate.filename.count("/") }
          while parents.present?
            parent = parents.shift
            parents = parents.map { |c| c.filename !~ /^#{parent.filename}\// ? c : nil }.compact
            categories << parent
          end
          categories
        end
    end
  end
end
