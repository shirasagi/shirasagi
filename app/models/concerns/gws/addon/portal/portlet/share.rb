module Gws::Addon::Portal::Portlet
  module Share
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      belongs_to :share_folder, class_name: "Gws::Share::Folder"
      embeds_ids :share_categories, class_name: "Gws::Share::Category"
      permit_params :share_folder_id, share_category_ids: []
    end

    def share_folder_options
      Gws::Share::Folder.site(@cur_site)
        .allow(:read, @cur_user, site: @cur_site)
        .pluck(:name, :id)
    end

    def find_share_items(portal, user)
      search = { site: portal.site }

      if cate = share_categories.first
        search[:category] = cate.name
      end
      if folder = share_folder
        search[:folder] = folder.id
      end

      Gws::Share::File.site(portal.site).
        readable(user, site: portal.site).
        active.
        search(search).
        order(updated: -1).
        page(1).
        per(limit)
    end
  end
end
