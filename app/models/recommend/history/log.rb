class Recommend::History::Log
  include SS::Document
  include SS::Reference::Site

  index({ created: -1 })

  field :token, type: String
  field :path, type: String
  field :access_url, type: String
  field :target_id, type: String
  field :target_class, type: String
  field :remote_addr, type: String
  field :user_agent, type: String

  validates :token, presence: true
  validates :path, presence: true
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

  def redis_key
    self.class.redis_key(site, path)
  end

  class << self
    def enable_access_logging?(site)
      Recommend::Part::Base.site(site).blank?
    end

    def to_config(opts = {})
      h = { recommend: {} }
      site = opts[:site]
      preview_path = opts[:preview_path]

      return h if preview_path
      return h if enable_access_logging?(site)

      item = opts[:item]
      path = opts[:path]
      path = path + "index.html" if path =~ /\/$/
      receiver_path = Rails.application.routes.url_helpers.recommend_history_receiver_path(site: site.id)
      receiver_url = ::File.join(site.full_url, receiver_path)

      h[:recommend][:receiver_url] = receiver_url
      h[:recommend][:params] = {}
      h[:recommend][:params][:path] = path
      if item
        h[:recommend][:params][:target_class] = item.class.to_s
        h[:recommend][:params][:target_id] = item.id
      end

      h
    end

    def redis_key(site, path)
      CGI.escape(::File.join(site.full_url, path))
    end

    def from_redis_keys(site, keys, limit = 50)
      keys.map do |key|
        path = "/" + CGI.unescape(key).sub(site.full_url, "")
        self.site(site).where(path: path).first
      end.compact
    end
  end
end
