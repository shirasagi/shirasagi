class Recommend::History::Log
  include SS::Document
  include SS::Reference::Site

  index({ created: -1 })

  field :url, type: String
  field :path, type: String
  field :token, type: String

  validates :url, presence: true
  validates :path, presence: true
  validates :token, presence: true
  before_validation :set_token

  default_scope -> { order_by(created: -1) }

  def set_token
    return if token
    self.token = SecureRandom.hex(16)
  end

  def content
    filename = path.sub(/^\//, "")
    page = Cms::Page.site(site).where(filename: filename).first
    return page if page

    filename = filename.sub(/\/index\.html$/, "")
    node = Cms::Node.site(site).where(filename: filename).first
    return node if node

    return nil
  end

  class << self
    def to_config(opts = {})
      site = opts[:site]
      path = opts[:path]
      path = path + "index.html" if path =~ /\/$/
      preview_path = opts[:preview_path]
      receiver_path = Rails.application.routes.url_helpers.recommend_history_receiver_path(site: site.id)
      receiver_url = ::File.join(site.full_url, receiver_path)

      h = {}
      h[:recommend] = {}
      return h if preview_path
      return h if Recommend::Part::Base.site(site).blank?

      h[:recommend][:receiver_url] = receiver_url
      h[:recommend][:path] = path
      h
    end
  end
end
