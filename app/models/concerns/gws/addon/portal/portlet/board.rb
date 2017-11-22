module Gws::Addon::Portal::Portlet
  module Board
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      embeds_ids :board_categories, class_name: "Gws::Board::Category"
      permit_params board_category_ids: []
    end

    def find_board_items(portal, user)
      search = { site: portal.site }

      if cate = board_categories.first
        search[:category] = cate.name
      end

      Gws::Board::Topic.site(portal.site).
        topic.
        and_public.
        readable(user, portal.site).
        search(search).
        order(descendants_updated: -1).
        page(1).
        per(limit)
    end
  end
end
