class Gws::Tabular::View::Base
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Tabular::Space
  include Gws::Reference::Tabular::Form
  include Gws::ReadableSetting
  include Gws::GroupPermission

  AUTHORING_PERMISSIONS = I18n.t("gws/tabular.options.authoring_permission", locale: I18n.default_locale).keys.map(&:to_s).freeze
  DEFAULT_AUTHORING_PERMISSION = "read".freeze

  store_in collection: 'gws_tabular_views'
  set_permission_name "gws_tabular_views"

  no_needs_read_permission_to_read

  field :i18n_name, type: String, localize: true
  field :authoring_permissions, type: SS::Extensions::Words
  field :state, type: String, default: 'closed'
  field :order, type: Integer, default: 0
  field :default_state, type: String
  field :memo, type: String

  alias name i18n_name
  alias name= i18n_name=

  permit_params :form_id, :name, :description, :state, :order, :default_state, :memo
  permit_params :i18n_name, i18n_name_translations: I18n.available_locales
  permit_params authoring_permissions: []

  before_validation :normalize_authoring_permissions

  validates :space, presence: true
  validates :form, presence: true
  validate :validate_i18n_name
  validates :authoring_permissions, inclusion: { in: AUTHORING_PERMISSIONS, allow_blank: true }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :default_state, inclusion: { in: %w(disabled enabled), allow_blank: true }

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
      search_fields.push("memo")
      all.keyword_in(params[:keyword], *search_fields)
    end

    def and_public(_date = nil)
      all.where(state: "public")
    end

    def and_default
      all.where(default_state: "enabled")
    end
  end

  def authoring_allowed?(premission)
    authoring_any_allowed?(premission)
  end

  def authoring_any_allowed?(*premissions)
    return false if authoring_permissions.blank?
    premissions.any? { authoring_permissions.include?(_1.to_s) }
  end

  def state_options
    %w(closed public).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def state_label(now = Time.zone.now)
    label(:state)
  end

  def public?
    state == "public"
  end

  def closed?
    !public?
  end

  def default_state_options
    %w(disabled enabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }
  end

  def default?
    default_state == 'enabled'
  end

  def order_hash
    {}
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

  def normalize_authoring_permissions
    return unless authoring_permissions_changed?
    return if authoring_permissions.blank?

    permissions = authoring_permissions.map(&:strip).select(&:present?).uniq
    permissions.push(DEFAULT_AUTHORING_PERMISSION) unless permissions.include?(DEFAULT_AUTHORING_PERMISSION)
    permissions.sort!

    self.authoring_permissions = permissions
  end
end
