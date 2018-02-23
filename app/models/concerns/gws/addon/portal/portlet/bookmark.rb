module Gws::Addon::Portal::Portlet
  module Bookmark
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :bookmark_model, type: String

      permit_params :bookmark_model

      validates :bookmark_model, inclusion: { in: (%w(other) << Gws::Bookmark::BOOKMARK_MODEL_TYPES).flatten, allow_blank: true }
    end

    def bookmark_model_options
      options = Gws::Bookmark::BOOKMARK_MODEL_TYPES.map do |model_type|
        [@cur_site.try(:"menu_#{model_type}_label") || I18n.t("modules.gws/#{model_type}"), model_type]
      end
      options.push([I18n.t('gws/bookmark.options.bookmark_model.other'), 'other'])
    end

    def find_bookmark_items(portal, user)
      Gws::Bookmark.site(portal.site).
        user(user).
        without_deleted.
        search({ bookmark_model: bookmark_model }).
        page(1).
        per(limit)
    end
  end
end
