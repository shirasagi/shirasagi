class Ads::Banner
  include Cms::Model::Page
  include SS::Relation::File
  include Ads::Addon::Category
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "ads_banners"

  field :link_url, type: String

  belongs_to_file :file

  validates :link_url, presence: true
  #validates :file_id, presence: true

  before_save :seq_filename, if: ->{ basename.blank? }

  permit_params :link_url

  default_scope ->{ where(route: "ads/banner") }

  public
    def url
      super + "?redirect=#{link_url}"
    end

    def count_url
      url.sub(".html", ".html.count")
    end

  private
    def validate_filename
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
