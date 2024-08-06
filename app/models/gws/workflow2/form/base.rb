class Gws::Workflow2::Form::Base
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Workflow2::FormCategory
  include Gws::Addon::Workflow2::FormPurpose
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission

  set_permission_name :gws_workflow_forms

  readable_setting_include_custom_groups
  permission_include_custom_groups
  no_needs_read_permission_to_read

  field :i18n_name, type: String, localize: true
  field :order, type: Integer
  field :state, type: String, default: 'closed'
  field :i18n_description, type: String, localize: true
  field :memo, type: String

  alias name i18n_name
  alias name= i18n_name=
  alias description i18n_description
  alias description= i18n_description=

  permit_params :name, :order, :description, :memo
  permit_params :i18n_name, i18n_name_translations: I18n.available_locales
  permit_params :i18n_description, i18n_description_translations: I18n.available_locales

  validate :validate_i18n_name
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }

  # # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::Workflow2FormJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::Workflow2FormJob.callback

  class << self
    SEARCH_HANDLERS = %i[search_keyword search_category search_category_criteria search_purpose].freeze

    def and_public
      all.where(state: 'public')
    end

    def search(params)
      return all if params.blank?

      criteria = all
      SEARCH_HANDLERS.each do |handler|
        criteria = criteria.send(handler, params)
      end
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      search_fields = I18n.available_locales.map { |lang| "i18n_name.#{lang}" }
      search_fields += I18n.available_locales.map { |lang| "i18n_description.#{lang}" }
      all.keyword_in(params[:keyword], *search_fields, method: params[:keyword_operator] || "and")
    end

    def search_category(params)
      if params[:category_id].present? && params[:category_id].numeric?
        all.where(category_ids: params[:category_id].to_i)
      elsif params[:category_ids].present?
        category_ids = params[:category_ids].select(&:numeric?).map(&:to_i)
        all.where("$and" => category_ids.map { |category_id| { category_ids: category_id } })
      else
        all
      end
    end

    def search_category_criteria(params)
      return all if params.blank? || params[:category_criteria].blank?

      all.where(params[:category_criteria])
    end

    def search_purpose(params)
      return all if params.blank? || params[:purpose_id].blank?
      all.where(purpose_ids: params[:purpose_id].to_i)
    end
  end

  def i18n_default_name
    i18n_name_translations[I18n.default_locale]
  end

  def i18n_default_description
    i18n_description_translations[I18n.default_locale]
  end

  def state_options
    %w(closed public).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def closed?
    !public?
  end

  def public?
    state == 'public'
  end

  private

  def validate_i18n_name
    # validates :name, presence: true, length: { maximum: Gws.max_name_length }
    translations = i18n_name_translations
    if translations.blank? || translations[I18n.default_locale].blank?
      errors.add :i18n_name, :blank
    end

    I18n.available_locales.each do |locale|
      local_name = translations[locale]
      next if local_name.blank?

      if local_name.length > Gws.max_name_length
        errors.add :i18n_name, :too_long, count: Gws.max_name_length
      end
    end
  end
end
