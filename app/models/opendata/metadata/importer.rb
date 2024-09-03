class Opendata::Metadata::Importer
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Reference::Node
  include Opendata::Addon::Metadata::Importer
  include Opendata::Addon::Metadata::ImporterCategorySetting
  include Opendata::Addon::Metadata::ImporterEstatCategorySetting
  include Opendata::Addon::Metadata::ImporterAreaSetting
  include Opendata::Addon::Metadata::ImporterReport
  include Opendata::Addon::Metadata::ImporterNotice
  include Cms::Addon::GroupPermission
  include ActiveSupport::NumberHelper

  set_permission_name "opendata_metadata", :edit

  seqid :id

  field :name, type: String
  field :source_url, type: String
  field :state, type: String, default: "enabled"
  field :order, type: Integer, default: 0

  field :basicauth_state, type: String, default: "disabled"
  field :basicauth_username, type: String
  field :basicauth_password, type: String

  field :source_host, type: String

  validates :name, presence: true
  validates :source_url, presence: true
  validate :validate_host, if: -> { source_url.present? }

  has_many :datasets, class_name: 'Opendata::Dataset', dependent: :nullify, inverse_of: :metadata_importer
  has_many :reports, class_name: 'Opendata::Metadata::Importer::Report', dependent: :destroy, inverse_of: :importer

  permit_params :name, :source_url, :state, :order
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

  def state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def basicauth_state_options
    state_options
  end

  def basicauth_enabled?
    basicauth_state == "enabled"
  end
end
