class Ads::Banner
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include SS::Relation::File
  include Ads::Addon::Category
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "ads_banners"

  field :link_url, type: String
  field :additional_attr, type: Cms::Extensions::HtmlAttributes, default: ""

  belongs_to_file2 :file

  validates :link_url, presence: true
  validate :validate_link_url
  #validates :file_id, presence: true

  permit_params :link_url, :additional_attr

  after_generate_file :generate_relation_public_file, if: ->{ public? }
  after_remove_file :remove_relation_public_file

  default_scope ->{ where(route: "ads/banner") }

  def url
    uri = URI.parse(super)
    uri.query = { redirect: link_url }.to_param
    uri.to_s
  end

  def count_url
    url.sub(".html", ".html.count")
  end

  private

  def validate_link_url
    return if link_url.blank?

    errors.add :link_url, :invalid if link_url == '#'
  end
end
