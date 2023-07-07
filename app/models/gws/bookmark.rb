module Gws::Bookmark
  extend Gws::ModulePermission

  set_permission_name :gws_bookmarks, :edit

  module_function

  BOOKMARK_MODEL_TYPES = %w(
    portal notice schedule todo reminder presence memo bookmark attendance affair daily_report report workflow workload
    circular monitor survey board faq qna discussion share shared_address personal_address elasticsearch staff_record
  ).freeze
  BOOKMARK_MODEL_SPECIAL_TYPES = %w(external_link other).freeze
  BOOKMARK_MODEL_DEFAULT_TYPE = "external_link".freeze
  BOOKMARK_MODEL_FALLBACK_TYPE = "other".freeze
  BOOKMARK_MODEL_ALL_TYPES = (BOOKMARK_MODEL_TYPES + BOOKMARK_MODEL_SPECIAL_TYPES).freeze

  def bookmark_model_options_all(site)
    options = []
    private_options = []

    BOOKMARK_MODEL_TYPES.each do |model_type|
      next if site.nil?

      name = site.send("menu_#{model_type}_label") || I18n.t("modules.gws/#{model_type}")
      if site.menu_visible?(model_type)
        options << [name, model_type]
      else
        private_options << [name, model_type]
      end
    end

    BOOKMARK_MODEL_SPECIAL_TYPES.each do |model_type|
      options << [I18n.t("gws/bookmark.options.bookmark_model.#{model_type}"), model_type]
    end

    [options, private_options]
  end
end
