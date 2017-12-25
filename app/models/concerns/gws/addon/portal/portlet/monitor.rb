module Gws::Addon::Portal::Portlet
  module Monitor
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :monitor_answerable_article, type: String
      embeds_ids :monitor_categories, class_name: "Gws::Monitor::Category"
      permit_params :monitor_answerable_article, monitor_category_ids: []
    end

    def monitor_answerable_article_options
      Gws::Monitor::Topic.new.answerable_article_options
    end

    def find_monitor_items(portal, user, group)
      search = { site: portal.site }

      if cate = monitor_categories.first
        search[:category] = cate.name
      end

      custom_group_ids = Gws::CustomGroup.site(portal.site).readable(user, site: portal.site).pluck(:id)
      state = monitor_answerable_article.presence || 'answerble'

      Gws::Monitor::Topic.site(portal.site).
        topic.
        and_public.
        search(search).
        and_topics(user.id, group.id, custom_group_ids, state).
        custom_order('updated_desc').
        page(1).
        per(limit)
    end
  end
end
