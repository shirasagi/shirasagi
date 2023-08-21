module Gws::Addon::Portal::Portlet
  module Faq
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      embeds_ids :faq_categories, class_name: "Gws::Faq::Category"
      permit_params faq_category_ids: []
    end

    def find_faq_items(portal, user)
      search = { site: portal.site }

      if cate = faq_categories.first
        search[:category] = cate.name
      end

      Gws::Faq::Topic.site(portal.site).
        topic.
        without_deleted.
        and_public.
        readable(user, site: portal.site).
        search(search).
        order(descendants_updated: -1).
        page(1).
        per(limit)
    end
  end
end
