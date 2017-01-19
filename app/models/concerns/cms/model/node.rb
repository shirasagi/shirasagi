module Cms::Model::Node
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::Reference::Layout
  include Cms::Reference::PageLayout
  include Cms::Reference::StCategory
  include Facility::Reference::Category
  include Facility::Reference::Service
  include Facility::Reference::Location

  included do
    store_in collection: "cms_nodes"
    set_permission_name "cms_nodes"

    field :route, type: String
    field :view_route, type: String
    field :shortcut, type: String, default: "hide"

    permit_params :view_route, :shortcut

    validates :route, presence: true
    validate :validate_invalid_filename

    after_save :rename_children, if: ->{ @db_changes }
    after_save :remove_directory, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_destroy :remove_directory
    after_destroy :destroy_children

    scope :root, ->{ where depth: 1 }
    scope :in_path, ->(path) {
      paths = Cms::Node.split_path(path.sub(/^\//, ""))
      paths.pop if paths.last =~ /\./
      where :filename.in => paths
    }

    template_variable_handler('pages.count', :template_variable_handler_pages_count)
  end

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

  def preview_path
    site.subdir ?  "#{site.subdir}/#{filename}/" : "#{filename}/"
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

  def all_children(cond = {})
    nodes.where(cond).gt(depth: depth)
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
    Cms::Node.plugins.select { |name, path, enabled| enabled }.map { |name, path, enabled| [name, path] }
  end

  def shortcut_options
      [
        [I18n.t('views.options.state.show'), 'show'],
        [I18n.t('views.options.state.hide'), 'hide'],
      ]
  end

  def validate_destination_filename(dst)
    dst_dir = ::File.dirname(dst).sub(/^\.$/, "")

    return errors.add :filename, :empty if dst.blank?
    return errors.add :filename, :invalid if dst !~ /^([\w\-]+\/)*[\w\-]+(#{Regexp.escape(fix_extname || "")})?$/

    return errors.add :base, :same_filename if filename == dst
    return errors.add :filename, :taken if Cms::Node.site(site).where(filename: dst).first
    return errors.add :base, :exist_physical_file if Fs.exists?("#{site.path}/#{dst}")

    if dst_dir.present?
      dst_parent = Cms::Node.site(site).where(filename: dst_dir).first

      return errors.add :base, :not_found_parent_node if dst_parent.blank?
      return errors.add :base, :subnode_of_itself if filename == dst_parent.filename

      allowed = dst_parent.allowed?(:read, @cur_user, site: @cur_site)
      return errors.add :base, :not_have_parent_read_permission unless allowed
    end
  end

  def move(dst)
    validate_destination_filename(dst)
    return false unless errors.empty?

    self.cur_node = nil
    self.filename = dst
    self.basename = nil
    save
  end

  # returns admin side show path
  def private_show_path(*args)
    model = "node"
    options = args.extract_options!
    methods = []
    if parent.blank?
      options = options.merge(site: site || cur_site, id: self)
      methods << "cms_#{model}_path"
    else
      options = options.merge(site: site || cur_site, cid: parent, id: self)
      methods << "node_#{model}_path"
    end

    helper_mod = Rails.application.routes.url_helpers
    methods.each do |method|
      path = helper_mod.send(method, *args, options) rescue nil
      return path if path.present?
    end

    nil
  end

  def category_node?
    %w(category/node category/page opendata/category).include?(route)
  end

  private
    def validate_invalid_filename
      if filename == "fs"
        errors.add :basename, :invalid
        return
      end

      full_url = cur_site ? "#{cur_site.full_url}#{filename}/" : "#{site.full_url}#{filename}/"
      SS::Site.each do |s|
        if s.full_url == full_url
          errors.add :basename, :invalid
          break
        end
      end
    end

    def rename_children
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      src = "#{site.path}/#{@db_changes['filename'][0]}"
      dst = "#{site.path}/#{@db_changes['filename'][1]}"
      dst_dir = ::File.dirname(dst)

      Fs.mkdir_p dst_dir unless Fs.exists?(dst_dir)
      Fs.mv src, dst if Fs.exists?(src)

      src, dst = @db_changes["filename"]
      %w(nodes pages parts layouts).each do |name|
        send(name).where(filename: /^#{src}\//).each do |item|
          dst_filename = item.filename.sub(/^#{src}\//, "#{dst}\/")
          item.set(
            filename: dst_filename,
            depth: dst_filename.scan("/").size + 1
          )
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

    def template_variable_handler_pages_count(name, issuer)
      date = issuer.try(:cur_date) || Time.zone.now
      Cms::Page.site(issuer.site).
        and_public(date).
        or({ filename: /^#{filename}\//, depth: depth + 1 }, { category_ids: id }).
        count.to_s
    end
end
