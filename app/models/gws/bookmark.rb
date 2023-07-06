class Gws::Bookmark
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  BOOKMARK_MODEL_TYPES = %w(
    portal notice schedule schedule/todo reminder presence memo bookmark attendance affair daily_report report workflow
    workload circular monitor survey board faq qna discussion share shared_address personal_address elasticsearch
    staff_record
  ).freeze
  FALLBACK_BOOKMARK_MODEL_TYPE = "other".freeze

  set_permission_name 'gws_bookmarks', :edit

  seqid :id
  field :name, type: String
  field :url, type: String
  field :bookmark_model, type: String

  permit_params :name, :url, :bookmark_model

  validates :name, presence: true, length: { maximum: 80 }
  validates :url, presence: true
  validates :bookmark_model, presence: true, inclusion: { in: [ FALLBACK_BOOKMARK_MODEL_TYPE ] + BOOKMARK_MODEL_TYPES }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria = criteria.where(bookmark_model: params[:bookmark_model]) if params[:bookmark_model].present?
    criteria
  }

  default_scope ->{ order_by(updated: -1) }

  class << self
    def detect_model(model, url)
      mode, mod = parse_model(model)
      return mod if mode == "gws" && mod.present? && BOOKMARK_MODEL_TYPES.include?(mod)
      return FALLBACK_BOOKMARK_MODEL_TYPE if url.blank?

      route = Rails.application.routes.recognize_path(url, { method: "GET" }) rescue nil
      return FALLBACK_BOOKMARK_MODEL_TYPE if route.blank?

      mode, mod = parse_model(route[:controller])
      return mod if mode == "gws" && mod.present? && BOOKMARK_MODEL_TYPES.include?(mod)

      FALLBACK_BOOKMARK_MODEL_TYPE
    end

    private

    def parse_model(model)
      mode, mod, remains = model.split("/", 3)
      mod = "#{mod}/todo" if mode == "gws" && remains.present? && remains.start_with?("todo")

      [ mode, mod ]
    end
  end

  def bookmark_model_options
    options = BOOKMARK_MODEL_TYPES.map do |model_type|
      [@cur_site.try(:"menu_#{model_type}_label") || I18n.t("modules.gws/#{model_type}"), model_type]
    end
    options.push([I18n.t("gws/bookmark.options.bookmark_model.#{FALLBACK_BOOKMARK_MODEL_TYPE}"), FALLBACK_BOOKMARK_MODEL_TYPE])
  end
end
