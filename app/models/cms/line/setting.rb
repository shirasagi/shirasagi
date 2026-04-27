class Cms::Line::Setting
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission

  TEMPLATE_TYPES = %w(text image page json_body).freeze

  set_permission_name "cms_line_settings", :use

  seqid :id
  field :template_types, type: Array, default: []

  permit_params template_types: []

  before_validation :set_default_template_types, if: -> { new_record? && template_types.blank? }
  validate :validate_template_types

  def template_type_options
    TEMPLATE_TYPES.map { |type| [I18n.t("cms.options.line_template_type.#{type}"), type] }
  end

  private

  def set_default_template_types
    self.template_types = TEMPLATE_TYPES
  end

  def validate_template_types
    self.template_types = template_types.select(&:present?)
    self.template_types << "text" if !template_types.include?("text")

    if (template_types - TEMPLATE_TYPES).present?
      self.errors.add :template_types, :inclusion
    end
  end

  class << self
    def with_site(site)
      self.find_or_create_by(site_id: site.id)
    end
  end
end
