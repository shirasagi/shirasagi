class Translate::TextCache
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_tools", :use

  index({ updated: -1 })
  index({ site_id: 1, hexdigest: 1 })

  attr_accessor :key

  field :api, type: String
  field :update_state, type: String, default: "auto"
  field :text, type: String, metadata: { normalize: false }
  field :original_text, type: String
  field :source, type: String
  field :target, type: String
  field :hexdigest, type: String

  permit_params :api
  permit_params :update_state
  permit_params :text
  permit_params :original_text
  permit_params :source
  permit_params :target

  validates :api, presence: true
  validates :update_state, presence: true
  validates :text, presence: true, if: -> { update_state == "manually" }
  validates :original_text, presence: true
  validates :source, presence: true
  validates :target, presence: true
  validates :hexdigest, presence: true, if: ->{ update_state != "manually" }
  validate :validate_hexdigest, if: ->{ update_state == "manually" }

  default_scope -> { order_by(updated: -1) }

  def validate_hexdigest
    return if api.blank?
    return if source.blank?
    return if target.blank?
    return if original_text.blank?

    self.hexdigest = self.class.hexdigest(api, source, target, original_text)
    if self.class.where(hexdigest: hexdigest).ne(id: id).first
      errors.add :base, :duplicate_hexdigest, original_text: original_text, source: source, target: target
    end
  end

  def api_options
    @_api_options ||= SS.config.translate.api_options.map { |k, v| [v, k] }
  end

  def update_state_options
    I18n.t("translate.options.update_state").map { |k, v| [v, k] }
  end

  class << self
    def hexdigest(api, source, target, original_text)
      Digest::MD5.hexdigest("#{api}_#{source}_#{target}_#{original_text}")
    end

    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :text, :original_text
      end
      if params[:target].present?
        criteria = criteria.where(target: params[:target])
      end
      if params[:update_state].present?
        criteria = criteria.where(update_state: params[:update_state])
      end
      criteria
    end
  end
end
