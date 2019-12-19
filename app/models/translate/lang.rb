class Translate::Lang
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Translate::Lang::Export

  set_permission_name "cms_tools", :use

  seqid :id
  field :code, type: String
  field :name, type: String
  field :mock_code, type: String
  field :google_translation_code, type: String
  field :microsoft_translator_text_code, type: String
  field :accept_languages, type: SS::Extensions::Lines, default: []

  permit_params :code
  permit_params :name
  permit_params :mock_code
  permit_params :google_translation_code
  permit_params :microsoft_translator_text_code
  permit_params :accept_languages

  validates :code, presence: true, uniqueness: { scope: :site_id }
  validates :name, presence: true
  validate :validate_accept_languages

  default_scope -> { order_by(code: 1) }

  def label
    "#{name}: #{code}"
  end

  def api_code
    try("#{(cur_site || site).translate_api}_code")
  end

  def validate_accept_languages
    self.accept_languages = accept_languages.to_a.select(&:present?).map(&:strip)
  end

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :code
      end
      criteria
    end
  end
end
