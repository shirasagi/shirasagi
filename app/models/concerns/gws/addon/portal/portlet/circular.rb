module Gws::Addon::Portal::Portlet
  module Circular
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :circular_article_state, type: String, default: "unseen"
      embeds_ids :circular_categories, class_name: "Gws::Circular::Category"
      permit_params circular_category_ids: []
      permit_params :circular_article_state
    end

    def find_circular_items(portal, user)
      search = { site: portal.site }

      if cate = circular_categories.first
        search[:category_id] = cate.id
      end

      if circular_article_state == 'unseen'
        search[:article_state] = "unseen"
        search[:user] = user
      else
        search[:article_state] = "both"
        search[:user] = user
      end

      Gws::Circular::Post.site(portal.site).
        topic.
        without_deleted.
        member(user).
        search(search).
        order(updated: -1).
        page(1).
        per(limit)
    end

    def circular_article_state_options
      Gws::Circular::Post.new.article_state_options
    end
  end
end
