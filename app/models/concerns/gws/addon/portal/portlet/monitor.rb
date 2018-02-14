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
      %w(unanswer answer).map do |v|
        [I18n.t("gws/monitor.tabs.#{v}"), v]
      end
    end

    def find_monitor_items(portal, user, group)
      search = { site: portal.site }

      if cate = monitor_categories.first
        search[:category] = cate.name
      end

      state = monitor_answerable_article.presence

      criteria = Gws::Monitor::Topic.site(portal.site).topic.and_public.
        and_attended(user, site: portal.site, group: group)
      if state == 'unanswer'
        criteria = criteria.and_unanswered(group)
      elsif state == 'answer'
        criteria = criteria.and_answered(group)
      end

      criteria.search(search).
        custom_order('due_date_desc').
        page(1).
        per(limit)
    end
  end
end
