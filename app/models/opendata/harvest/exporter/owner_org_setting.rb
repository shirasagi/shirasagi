class Opendata::Harvest::Exporter::OwnerOrgSetting
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission
  include ActiveSupport::NumberHelper

  belongs_to :exporter, class_name: 'Opendata::Harvest::Exporter'

  set_permission_name "other_opendata_harvests", :edit

  embeds_ids :groups, class_name: 'SS::Group'

  field :name, type: String
  field :ckan_id, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :ckan_id, :order
  permit_params group_ids: []

  seqid :id

  validates :name, presence: true
  validates :ckan_id, presence: true
  validates :exporter, presence: true

  default_scope ->{ order_by order: 1 }

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def match?(item)
    (group_ids & item.group_ids).present?
  end
end
