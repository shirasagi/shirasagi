module Gws::Addon::Portal::Portlet
  module Notice
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :notice_severity, type: String
      field :notice_browsed_state, type: String
      embeds_ids :notice_categories, class_name: "Gws::Notice::Category"
      embeds_ids :notice_folders, class_name: "Gws::Notice::Folder"
      permit_params :notice_severity, :notice_browsed_state, notice_category_ids: [], notice_folder_ids: []
    end

    def notice_severity_options
      [
        [I18n.t('gws.options.severity.high'), 'high'],
      ]
    end

    def notice_browsed_state_options
      %w(unread read).map { |m| [I18n.t("gws/board.options.browsed_state.#{m}"), m] }
    end

    def find_notice_items(portal, user)
      search = { site: portal.site }

      if notice_severity.present?
        search[:severity] = notice_severity
      end
      if cate = notice_categories.readable(user, site: portal.site).first
        search[:category] = cate.name
      end
      if notice_browsed_state.present?
        search[:user] = user
        search[:browsed_state] = notice_browsed_state
      end

      Gws::Notice::Post.site(portal.site).
        without_deleted.
        and_public.
        readable(user, site: portal.site).
        search(search).
        page(1).
        per(limit)
    end
  end
end
