module Gws::Bookmark
  class Item
    include SS::Document
    include Gws::Reference::User
    include Gws::Reference::Site
    include Gws::SitePermission

    BOOKMARK_MODEL_TYPES = %w(
      portal notice schedule schedule/todo reminder presence memo bookmark attendance affair daily_report report workflow workload
      circular monitor survey board faq qna discussion share shared_address personal_address elasticsearch staff_record
    ).freeze
    BOOKMARK_MODEL_SPECIAL_TYPES = %w(external_link other).freeze
    BOOKMARK_MODEL_DEFAULT_TYPE = "external_link".freeze
    BOOKMARK_MODEL_FALLBACK_TYPE = "other".freeze

    store_in collection: "gws_bookmarks"

    set_permission_name 'gws_bookmarks', :edit

    seqid :id
    field :name, type: String
    field :order, type: Integer
    field :url, type: String
    field :link_target, type: String, default: "_self"
    field :bookmark_model, type: String
    belongs_to :folder, class_name: "Gws::Bookmark::Folder", inverse_of: :items

    permit_params :name, :link_target, :order, :url, :bookmark_model, :folder_id

    validates :name, presence: true, length: { maximum: 80 }
    validates :url, presence: true
    validates :bookmark_model, presence: true, inclusion: { in: (BOOKMARK_MODEL_SPECIAL_TYPES + BOOKMARK_MODEL_TYPES) }
    validates :folder_id, presence: true

    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria = criteria.where(bookmark_model: params[:bookmark_model]) if params[:bookmark_model].present?
      criteria
    }

    default_scope ->{ order_by(order: 1, updated: -1) }

    class << self
      def detect_model(model, url)
        mode, mod = parse_model(model)
        return mod if mode == "gws" && mod.present? && BOOKMARK_MODEL_TYPES.include?(mod)
        return BOOKMARK_MODEL_FALLBACK_TYPE if url.blank?

        route = Rails.application.routes.recognize_path(url, { method: "GET" }) rescue nil
        return BOOKMARK_MODEL_FALLBACK_TYPE if route.blank?

        mode, mod = parse_model(route[:controller])
        return mod if mode == "gws" && mod.present? && BOOKMARK_MODEL_TYPES.include?(mod)

        BOOKMARK_MODEL_FALLBACK_TYPE
      end

      def and_folder(folder)
        where(folder_id: folder.id)
      end

      def allowed_bookmark_models
        Gws::Bookmark::Item::BOOKMARK_MODEL_TYPES + Gws::Bookmark::Item::BOOKMARK_MODEL_SPECIAL_TYPES
      end

      private

      def parse_model(model)
        mode, mod, remains = model.split("/", 3)
        mod = "#{mod}/todo" if mode == "gws" && remains.present? && remains.start_with?("todo")

        [ mode, mod ]
      end
    end

    def order
      value = self[:order].to_i
      value < 0 ? 0 : value
    end

    def bookmark_model_options_all
      self.site ||= cur_site

      options = []
      private_options = []
      BOOKMARK_MODEL_TYPES.each do |model_type|
        next if site.nil?

        name = site.send(:"menu_#{model_type}_label") || I18n.t("modules.gws/#{model_type}")
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

    def bookmark_model_options
      bookmark_model_options_all[0]
    end

    def bookmark_model_private_options
      bookmark_model_options_all[1]
    end

    def link_target_options
      I18n.t("ss.options.link_target").map { |k, v| [v, k] }
    end

    def link_to_options
      options = {}
      options = { target: :_blank, rel: "noopener" } if link_target == "_blank"
      options
    end
  end
end
