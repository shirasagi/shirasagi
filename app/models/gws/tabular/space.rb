class Gws::Tabular::Space
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include SS::Relation::File

  readable_setting_include_custom_groups
  no_needs_read_permission_to_read
  permission_include_custom_groups

  field :i18n_name, type: String, localize: true
  field :state, type: String, default: 'closed'
  field :order, type: Integer, default: 0
  belongs_to_file :icon
  field :memo, type: String

  alias name i18n_name
  alias name= i18n_name=

  permit_params :name, :state, :order, :memo
  permit_params :i18n_name, i18n_name_translations: I18n.available_locales

  validate :validate_i18n_name
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  class << self
    SEARCH_HANDLERS = %i[search_keyword].freeze

    def search(params)
      criteria = all
      return criteria if params.blank?

      SEARCH_HANDLERS.each do |handler|
        criteria = criteria.send(handler, params)
      end
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?

      search_fields = I18n.available_locales.map { |lang| "i18n_name.#{lang}" }
      search_fields.append "memo"
      all.keyword_in(params[:keyword], *search_fields)
    end

    def and_public(_date = nil)
      all.where(state: "public")
    end
  end

  def state_options
    %w(closed public).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def state_label(_now = nil)
    label(:state)
  end

  def main_path(**options)
    Rails.application.routes.url_helpers.then do |helper|
      helper.gws_tabular_main_path(site: self.site_id, space: self, **options)
    end
  end

  private

  def validate_i18n_name
    # validates :name, presence: true, length: { maximum: SS.max_name_length }
    translations = i18n_name_translations
    if translations.blank? || translations[I18n.default_locale].blank?
      errors.add :i18n_name, :blank
    end

    I18n.available_locales.each do |locale|
      local_name = translations[locale]
      next if local_name.blank?

      if local_name.length > SS.max_name_length
        errors.add :i18n_name, :too_long, count: SS.max_name_length
      end
    end
  end
end
