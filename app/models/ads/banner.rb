class Ads::Banner
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include SS::Relation::File
  include Ads::Addon::Category
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Cms::Lgwan::Page

  set_permission_name "ads_banners"

  AVAILABLE_LINK_TARGETS = %w(_self _blank).freeze

  field :link_url, type: String
  field :link_target, type: String

  belongs_to_file :file

  before_validation :encode_link_url

  validates :link_url, presence: true, url: { absolute_path: true }
  validate :validate_link_url
  validates :link_target, inclusion: { in: AVAILABLE_LINK_TARGETS, allow_blank: true }
  #validates :file_id, presence: true

  permit_params :link_url, :link_target

  after_generate_file :generate_relation_public_file, if: ->{ public? }
  after_remove_file :remove_relation_public_file

  default_scope ->{ where(route: "ads/banner") }

  template_variable_handler :link_url, :template_variable_handler_link_url
  template_variable_handler :link_target, :template_variable_handler_name
  template_variable_handler 'img.src', :template_variable_handler_img_src

  liquidize do
    export :link_url
    export :link_target
    export :file
  end

  def self.link_target_options
    AVAILABLE_LINK_TARGETS.map { [ I18n.t(_1, scope: "ads.options.link_target"), _1 ] }
  end
  delegate :link_target_options, to: :class

  def url
    uri = ::Addressable::URI.parse(super)
    uri.query = { redirect: link_url }.to_param
    uri.to_s
  end

  def count_url
    url.sub(".html", ".html.count")
  end

  private

  def encode_link_url
    return if link_url.blank?
    self.link_url = SS.follow_up_url_encode(link_url)
  end

  def validate_link_url
    return if link_url.blank?

    errors.add :link_url, :invalid if link_url == '#'
  end

  def template_variable_handler_link_url(_name, _issuer)
    SS.follow_up_url_encode(link_url.presence || url)
  end

  def template_variable_handler_img_src(_name, _issuer)
    if file
      SS.follow_up_url_encode(file.url)
    end
  end
end
