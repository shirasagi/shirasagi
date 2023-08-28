module Gws::Addon::Portal::Portlet
  module Circular
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :circular_article_state, type: String
      field :circular_sort, type: String

      embeds_ids :circular_categories, class_name: "Gws::Circular::Category"
      permit_params circular_category_ids: []
      permit_params :circular_article_state, :circular_sort

      before_validation :set_default_circular_setting
    end

    def find_circular_items(portal, user)
      search = { site: portal.site }

      if cate = circular_categories.first
        search[:category_id] = cate.id
      end

      if circular_article_state == 'unseen'
        search[:article_state] = "unseen"
      else
        search[:article_state] = "both"
      end
      search[:user] = user

      criteria = Gws::Circular::Post.site(portal.site)
      criteria = criteria.topic
      criteria = criteria.without_deleted
      criteria = criteria.and_public
      criteria = criteria.member(user)
      criteria = criteria.search(search)
      criteria = criteria.order(updated: -1)
      if circular_sort.present?
        criteria = criteria.custom_order(circular_sort)
      end
      criteria.page(1).per(limit)
    end

    def circular_article_state_options
      Gws::Circular::Post.new.article_state_options
    end

    def circular_sort_options
      Gws::Circular::Post.new.sort_options
    end

    def see_more_circular_path(portal, user)
      search = {}

      if circular_article_state.present?
        search[:article_state] = circular_article_state
      end
      if circular_sort.present?
        search[:sort] = circular_sort
      end

      url_helper = Rails.application.routes.url_helpers
      url_helper.gws_circular_posts_path(site: portal.site, s: search)
    end

    private

    def set_default_circular_setting
      site = cur_site || site
      return unless site

      if circular_article_state.blank?
        self.circular_article_state = site.circular_article_state
      end
      if circular_sort.blank?
        self.circular_sort = site.circular_sort
      end
    end
  end
end
