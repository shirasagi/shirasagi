module Gws::Addon::Portal::Portlet
  module Qna
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      embeds_ids :qna_categories, class_name: "Gws::Qna::Category"
      permit_params qna_category_ids: []
    end

    def find_qna_items(portal, user)
      search = { site: portal.site }

      if cate = qna_categories.first
        search[:category] = cate.name
      end

      Gws::Qna::Topic.site(portal.site).
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
