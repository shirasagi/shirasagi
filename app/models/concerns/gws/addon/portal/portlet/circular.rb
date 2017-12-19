module Gws::Addon::Portal::Portlet
  module Circular
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      embeds_ids :circular_categories, class_name: "Gws::Circular::Category"
      permit_params circular_category_ids: []
    end

    def find_circular_items(portal, user)
      search = { site: portal.site }

      if cate = circular_categories.first
        search[:category_id] = cate.id
      end

      Gws::Circular::Post.site(portal.site).
        without_deleted.
        readable(user, portal.site).
        search(search).
        and_my_draft(user).
        order(updated: -1).
        page(1).
        per(limit)
    end
  end
end
