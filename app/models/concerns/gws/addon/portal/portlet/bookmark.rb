module Gws::Addon::Portal::Portlet
  module Bookmark
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :bookmark_model, type: String

      belongs_to :bookmark_folder, class_name: "Gws::Bookmark::Folder"

      permit_params :bookmark_model, :bookmark_folder_id

      validates :bookmark_model, inclusion: { in: Gws::Bookmark::Item.allowed_bookmark_models, allow_blank: true }
    end

    def bookmark_model_options
      @bookmark_model_options ||= Gws::Bookmark.bookmark_model_options_all(@cur_site || site)[0]
    end

    def bookmark_model_private_options
      @bookmark_model_private_options ||= Gws::Bookmark.bookmark_model_options_all(@cur_site || site)[1]
    end

    def find_bookmark_items(portal, user)
      criteria = Gws::Bookmark::Item.site(portal.site)
      criteria = criteria.user(user)
      criteria = criteria.without_deleted
      if bookmark_folder.present?
        criteria = criteria.and_folder(bookmark_folder)
      end
      if bookmark_model.present?
        criteria = criteria.search(bookmark_model: bookmark_model)
      end
      criteria = criteria.page(1)
      criteria.per(limit)
    end
  end
end
