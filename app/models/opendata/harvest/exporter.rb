class Opendata::Harvest::Exporter
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::Addon::GroupPermission
  include Opendata::Harvest::CkanApiExporter
  include ActiveSupport::NumberHelper

  set_permission_name "opendata_harvests", :edit

  seqid :id

  field :name, type: String
  field :url, type: String
  field :api_type, type: String
  field :api_key, type: String
  field :order, type: Integer, default: 0

  field :host, type: String
  field :deleted_resources, type: Array, default: []

  has_many :group_settings, class_name: 'Opendata::Harvest::Exporter::GroupSetting',
    dependent: :destroy, inverse_of: :exporter
  has_many :owner_org_settings, class_name: 'Opendata::Harvest::Exporter::OwnerOrgSetting',
    dependent: :destroy, inverse_of: :exporter
  has_many :dataset_relations, class_name: 'Opendata::Harvest::Exporter::DatasetRelation',
    dependent: :destroy, inverse_of: :exporter

  validates :name, presence: true
  validates :api_type, presence: true
  validates :url, presence: true
  validates :api_key, presence: true
  validate :validate_host, if: -> { url.present? }

  permit_params :name, :url, :api_type, :api_key, :order

  default_scope -> { order_by(order: 1) }

  private

  def validate_host
    self.host = ::URI.parse(url).host
  rescue => e
    errors.add :host, :invalid
  end

  public

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def api_type_options
    I18n.t("opendata.harvest_exporter_api_options").map { |k, v| [v, k] }
  end
end
