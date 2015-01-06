module Cms::Node::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::Reference::Layout
  include Cms::Reference::PageLayout
  include Cms::Reference::StCategory
  include Cms::Addon::NodeSetting
  include Cms::Addon::Meta
  include Cms::Addon::Release
  include History::Addon::Backup
  include Facility::Reference::Category
  include Facility::Reference::Service
  include Facility::Reference::Location

  included do
    store_in collection: "cms_nodes"
    set_permission_name "cms_nodes"

    field :route, type: String
    field :shortcut, type: String, default: "hide"

    permit_params :shortcut

    validates :route, presence: true

    after_save :rename_children, if: ->{ @db_changes }
    after_save :remove_directory, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_destroy :remove_directory
    after_destroy :destroy_children

    scope :root, ->{ where(depth: 1) }
    scope :in_path, ->(path) { where :filename.in => Cms::Node.split_path(path.sub(/^\//, "")) }
  end

  public
    def becomes_with_route(name = nil)
      super (name || route).sub("/", "/node/")
    end

    def dirname
      filename.index("/") ? filename.to_s.sub(/\/[^\/]+$/, "").presence : nil
    end

    def url
      "#{site.url}#{filename}/"
    end

    def full_url
      "#{site.full_url}#{filename}/"
    end

    def date
      updated || created
    end

    def parents
      dirs = self.class.split_path(filename)
      dirs.pop
      Cms::Node.where(site_id: site_id, :filename.in => dirs).sort(depth: 1)
    end

    def nodes
      Cms::Node.where(site_id: site_id, filename: /^#{filename}\//)
    end

    def children(cond = {})
      nodes.where cond.merge(depth: depth + 1)
    end

    def pages
      Cms::Page.where(site_id: site_id, filename: /^#{filename}\//)
    end

    def parts
      Cms::Part.where(site_id: site_id, filename: /^#{filename}\//)
    end

    def layouts
      Cms::Layout.where(site_id: site_id, filename: /^#{filename}\//)
    end

    def route_options
      Cms::Node.plugins
    end

    def shortcut_options
      [%w(表示 show), %w(非表示 hide)]
    end

  private
    def rename_children
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      src = "#{site.path}/#{@db_changes['filename'][0]}"
      dst = "#{site.path}/#{@db_changes['filename'][1]}"
      Fs.mv src, dst if Fs.exists?(src)

      src, dst = @db_changes["filename"]
      %w(nodes pages parts layouts).each do |name|
        send(name).where(filename: /^#{src}\//).each do |item|
          item.filename = item.filename.sub(/^#{src}\//, "#{dst}\/")
          item.save validate: false
        end
      end
    end

    def remove_directory
      Fs.rm_rf path
    end

    def destroy_children
      %w(nodes pages parts layouts).each do |name|
        send(name).destroy_all
      end
    end
end
