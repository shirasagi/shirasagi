class Recommend::History::Log
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

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

  set_permission_name "cms_sites", :edit

  def set_token
    return if token
    self.token = SecureRandom.hex(16)
  end

  def content
    filename = path.sub(/^#{site.url}/, "")
    page = Cms::Page.site(site).where(filename: filename).first
    return page if page

    filename = filename.sub(/\/index\.html$/, "")
    node = Cms::Node.site(site).where(filename: filename).first
    return node if node

    return nil
  end

  class << self
    def enable_access_logging?(site)
      SS::Config.recommend.disable.blank?
      #Recommend::Part::Base.site(site).present?
    end

    def to_config(opts = {})
      h = { recommend: {} }
      site = opts[:site]
      preview_path = opts[:preview_path]

      return h if preview_path
      return h unless enable_access_logging?(site)

      item = opts[:item]
      path = opts[:path]
      path += "index.html" if path =~ /\/$/
      receiver_path = Rails.application.routes.url_helpers.recommend_history_receiver_path(site: site.id)
      receiver_url = ::File.join(site.full_root_url, receiver_path)

      h[:recommend][:receiver_url] = receiver_url
      h[:recommend][:params] = {}
      h[:recommend][:params][:path] = path
      if item
        h[:recommend][:params][:target_class] = item.class.to_s
        h[:recommend][:params][:target_id] = item.id
      end

      h
    end

    def to_path_axis_aggregation(match = {})
      pipes = []
      pipes << { "$match" => match } if match.present?
      pipes << { "$group" =>
        {
          "_id" => { "path" => "$path", "token" => "$token" },
          "count" => { "$sum" => 1 }
        }
      }
      pipes << { "$group" =>
        {
          "_id" => { "path" => "$_id.path" },
          "tokens" => { "$push" => { token: "$_id.token", count: "$count" } }
        }
      }
      aggregation = Recommend::History::Log.collection.aggregate(pipes)

      prefs = {}
      aggregation = aggregation.each do |i|
        path = i["_id"]["path"]

        tokens = {}
        i["tokens"].each do |h|
          token = h["token"]
          count = h["count"]
          tokens[token] = count
        end

        prefs[path] = tokens
      end

      prefs
    end

    def to_token_axis_aggregation(match = {})
      pipes = []
      pipes << { "$match" => match } if match.present?
      pipes << { "$group" =>
        {
          "_id" => { "path" => "$path", "token" => "$token" },
          "count" => { "$sum" => 1 }
        }
      }
      pipes << { "$group" =>
        {
          "_id" => { "token" => "$_id.token" },
          "paths" => { "$push" => { path: "$_id.path", count: "$count" } }
        }
      }
      aggregation = Recommend::History::Log.collection.aggregate(pipes)

      prefs = {}
      aggregation = aggregation.each do |i|
        token = i["_id"]["token"]

        paths = {}
        i["paths"].each do |h|
          path = h["path"]
          count = h["count"]
          paths[path] = count
        end

        prefs[token] = paths
      end

      prefs
    end
  end
end
