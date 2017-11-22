module Gws::Addon::Portal::Portlet
  module Share
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :limit, type: Integer, default: 5
      belongs_to :share_folder, class_name: "Gws::Share::Folder"
      embeds_ids :share_categories, class_name: "Gws::Share::Category"
      permit_params :limit, :share_folder_id, share_category_ids: []
    end

    def find_items(portal, cur_user)
      search = { site: portal.site }

      if cate = share_categories.first
        search[:category] = cate.name
      end
      if folder = share_folder
        search[:folder] = folder.id
      end

      Gws::Share::File.site(portal.site).
        readable(cur_user, portal.site).
        active.
        search(search).
        order(updated: -1).
        page(1).
        per(limit)
    end

    def share_folder_options
      item = Gws::Share::File.new(cur_user: @cur_user, cur_site: @cur_site)
      item.folder_options
    end
  end
end
