class Opendata::Harvest::Importer
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Reference::Node
  include Opendata::Addon::Harvest::Importer
  include Opendata::Addon::Harvest::ImporterCategorySetting
  include Opendata::Addon::Harvest::ImporterEstatCategorySetting
  include Opendata::Addon::Harvest::ImporterAreaSetting
  include Opendata::Addon::Harvest::ImporterReport
  include Cms::Addon::GroupPermission
  include ActiveSupport::NumberHelper

  set_permission_name "opendata_harvests", :edit

  seqid :id

  field :name, type: String
  field :source_url, type: String
  field :state, type: String, default: "enabled"
  field :api_type, type: String
  field :order, type: Integer, default: 0
  field :resource_size_limit_mb, type: Integer, default: 0

  field :basicauth_state, type: String, default: "disabled"
  field :basicauth_username, type: String
  field :basicauth_password, type: String

  field :source_host, type: String

  validates :name, presence: true
  validates :api_type, presence: true
  validates :source_url, presence: true
  validate :validate_host, if: -> { source_url.present? }

  has_many :datasets, class_name: 'Opendata::Dataset', dependent: :nullify, inverse_of: :harvest_importer
  has_many :reports, class_name: 'Opendata::Harvest::Importer::Report', dependent: :destroy, inverse_of: :importer

  permit_params :name, :source_url, :state, :api_type, :order, :resource_size_limit_mb
  permit_params :basicauth_state, :basicauth_username, :basicauth_password

  default_scope -> { order_by(order: 1) }

  private

  def validate_host
    self.source_host = ::URI.parse(source_url).host
  rescue => e
    errors.add :source_host, :invalid
  end

  public

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def api_type_options
    SS.config.opendata.harvest["importer_api"].map do |k|
      [ I18n.t("opendata.harvest_importer_api_options.#{k}"), k ]
    end
  end

  def state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def enabled?
    state == "enabled"
  end

  def basicauth_state_options
    state_options
  end

  def basicauth_enabled?
    basicauth_state == "enabled"
  end
end
