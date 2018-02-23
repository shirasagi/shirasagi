module Gws::Addon::Portal::Portlet
  module Board
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :board_severity, type: String
      embeds_ids :board_categories, class_name: "Gws::Board::Category"
      permit_params :board_severity, board_category_ids: []
    end

    def board_severity_options
      %w(normal important).map { |v| [ I18n.t("gws/board.options.severity.#{v}"), v ] }
    end

    def find_board_items(portal, user)
      search = { site: portal.site }

      if board_severity.present?
        search[:severity] = board_severity
      end
      if cate = board_categories.first
        search[:category] = cate.name
      end

      Gws::Board::Topic.site(portal.site).
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
