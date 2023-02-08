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

      before_validation :set_default_notice_setting

      permit_params :notice_severity, :notice_browsed_state, notice_category_ids: [], notice_folder_ids: []
    end

    def notice_severity_options
      %w(all high).map { |m| [I18n.t("gws/notice.options.severity.#{m}"), m] }
    end

    def notice_browsed_state_options
      %w(both unread read).map { |m| [I18n.t("gws/board.options.browsed_state.#{m}"), m] }
    end

    def find_notice_items(portal, user)
      search = { site: portal.site }

      if notice_severity.present?
        search[:severity] = notice_severity
      end
      category_ids = notice_categories.readable(user, site: portal.site).pluck(:id)
      if category_ids.present?
        search[:category_ids] = category_ids
      end
      folder_ids = notice_folders.readable(user, site: portal.site).pluck(:id)
      if folder_ids.present?
        search[:folder_ids] = folder_ids
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

    private

    def set_default_notice_setting
      site = cur_site || site
      return unless site

      if notice_severity.blank?
        self.notice_severity = site.notice_severity
      end
      if notice_browsed_state.blank?
        self.notice_browsed_state = site.notice_browsed_state
      end
    end
  end
end
