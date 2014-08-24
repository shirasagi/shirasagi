# coding: utf-8
module Cms::Reference

  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :cms_roles, class_name: "Cms::Role"
      permit_params cms_role_ids: []

      public
        def cms_role_level(site)
          cms_roles.site(site).pluck(:permission_level).max
        end
    end
  end

  module Layout
    extend ActiveSupport::Concern

    included do
      belongs_to :layout, class_name: "Cms::Layout"
      permit_params :layout_id
    end
  end
  
  module StCategory
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Category::Node::Base"
      permit_params category_ids: []
    end
  end
end
