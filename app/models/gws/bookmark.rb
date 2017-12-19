class Gws::Bookmark
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::UserPermission

  BOOKMARK_MODEL_TYPES = %w(
    portal reminder bookmark schedule memo board faq qna report workflow
    circular discussion monitor share shared_address elasticsearch staff_record
  ).freeze

  seqid :id
  field :name, type: String
  field :url, type: String
  field :bookmark_model, type: String

  permit_params :name, :url, :bookmark_model

  validates :name, presence: true, length: { maximum: 80 }
  validates :url, presence: true
  validates :bookmark_model, presence: true, inclusion: { in: (%w(other) << BOOKMARK_MODEL_TYPES).flatten }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria = criteria.where(bookmark_model: params[:bookmark_model]) if params[:bookmark_model].present?
    criteria
  }

  def bookmark_model_options
    options = BOOKMARK_MODEL_TYPES.map do |model_type|
      [@cur_site.try(:"menu_#{model_type}_label") || I18n.t("modules.gws/#{model_type}"), model_type]
    end
    options.push([I18n.t('gws.options.bookmark_model.other'), 'other'])
  end
end
