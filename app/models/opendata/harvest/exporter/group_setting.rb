class Opendata::Harvest::Exporter::GroupSetting
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission
  include ActiveSupport::NumberHelper

  belongs_to :exporter, class_name: 'Opendata::Harvest::Exporter'

  set_permission_name "other_opendata_harvests", :edit

  embeds_ids :categories, class_name: 'Opendata::Node::Category'
  embeds_ids :estat_categories, class_name: 'Opendata::Node::EstatCategory'

  field :name, type: String
  field :ckan_id, type: String
  field :ckan_name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :ckan_id, :ckan_name, :order
  permit_params category_ids: []
  permit_params estat_category_ids: []

  seqid :id

  validates :name, presence: true
  validates :ckan_id, presence: true
  validates :ckan_name, presence: true
  validates :exporter, presence: true

  default_scope ->{ order_by order: 1 }

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def match?(item)
    (category_ids & item.category_ids).present? || (estat_category_ids & item.estat_category_ids).present?
  end
end
