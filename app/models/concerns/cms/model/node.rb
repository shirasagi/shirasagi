module Cms::Model::Node
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::RedirectPage
  include Cms::Reference::Layout
  include Cms::Reference::PageLayout
  include Cms::Reference::StCategory
  include Facility::Reference::Category
  include Facility::Reference::Service
  include Facility::Reference::Location

  included do
    include Cms::Model::NodeDiscriminatorRetrieval

    store_in collection: "cms_nodes"
    set_permission_name "cms_nodes"

    attr_accessor :window_name, :skip_remove_files_recursively

    field :route, type: String
    field :view_route, type: String
    field :shortcut, type: String, default: "hide"

    permit_params :view_route, :shortcut

    validates :route, presence: true
    validate :validate_invalid_filename
    validate :validate_ancestors

    after_save :rename_children, if: ->{ @db_changes }
    after_save :remove_files_recursively, if: ->{ remove_files_recursively? }
    after_update :update_page_index_queues, if: ->{ @db_changes["state"] }
    after_destroy :remove_all
    after_destroy :destroy_children

    scope :root, ->{ where depth: 1 }
    scope :in_path, ->(path) {
      paths = Cms::Node.split_path(path.sub(/^\//, ""))
      paths.pop if paths.last =~ /\./
      where :filename.in => paths
    }

    template_variable_handler('pages.count', :template_variable_handler_pages_count)

    liquidize do
      export :nodes do |context|
        site = context.registers[:cur_site]
        date = context.registers[:cur_date]

        criteria = Cms::Node.site(site).and_public(date)
        if self.respond_to?(:condition_hash)
          criteria = criteria.where(self.condition_hash)
        else
          criteria = criteria.where({ filename: /^#{::Regexp.escape(self.filename)}\//, depth: self.depth + 1 })
        end
        criteria = criteria.reorder(self.sort_hash) if self.respond_to?(:sort_hash)
        criteria.to_a
      end
      export :pages do |context|
        site = context.registers[:cur_site]
        date = context.registers[:cur_date]

        criteria = Cms::Page.site(site).and_public(date)
        if self.respond_to?(:condition_hash)
          criteria = criteria.where(self.condition_hash)
        else
          criteria = criteria.where({ filename: /^#{::Regexp.escape(self.filename)}\//, depth: self.depth + 1 })
        end
        criteria = criteria.reorder(self.sort_hash) if self.respond_to?(:sort_hash)
        criteria.to_a
      end
    end
  end

  module ClassMethods
    def tree_sort(options = {})
      Cms::NodeTreeList.build self, options
    end
  end

  def becomes_with_route(name = nil)
    return self if name.blank?

    name = name.sub("/", "/node/")
    return self if route == name

    super name
  end

  def dirname
    filename.index("/") ? filename.to_s.sub(/\/[^\/]+$/, "").presence : nil
  end

  def url
    "#{(@cur_site || site).url}#{filename}/"
  end

  def full_url
    "#{(@cur_site || site).full_url}#{filename}/"
  end

  def preview_path
    (@cur_site || site).then do |s|
      s.subdir ? "#{s.subdir}/#{filename}/" : "#{filename}/"
    end
  end

  def mobile_preview_path
    (@cur_site || site).then do |s|
      ::File.join(s.subdir || "", s.mobile_location, filename, "/").gsub(/^\//, '')
    end
  end

  def parents
    dirs = self.class.split_path(filename)
    dirs.pop
    Cms::Node.where(site_id: site_id, :filename.in => dirs).sort(depth: 1)
  end

  def nodes
    Cms::Node.where(site_id: site_id, filename: /^#{::Regexp.escape(filename)}\//)
  end

  def children(cond = {})
    nodes.where cond.merge(depth: depth + 1)
  end

  def all_children(cond = {})
    nodes.where(cond).gt(depth: depth)
  end

  def any_ancestor_nodes_for_member_enabled?
    enabled_nodes = all_ancestor_nodes.find do |node|
      node.try(:for_member_state) == "enabled"
    end

    enabled_nodes.present?
  end

  def all_ancestor_nodes
    filenames = []
    self.filename.split("/").map do |v|
      filenames << v
      Cms::Node.find_by(site_id: site_id, filename: filenames.join("/")) rescue nil
    end
  end

  def pages
    Cms::Page.where(site_id: site_id, filename: /^#{::Regexp.escape(filename)}\//)
  end

  def parts
    Cms::Part.where(site_id: site_id, filename: /^#{::Regexp.escape(filename)}\//)
  end

  def layouts
    Cms::Layout.where(site_id: site_id, filename: /^#{::Regexp.escape(filename)}\//)
  end

  def route_options
    Cms::Node.plugins.select { |name, path, enabled| enabled }.map { |name, path, enabled| [name, path] }
  end

  def shortcut_options
    [
      [I18n.t('ss.options.state.show'), 'show'],
      [I18n.t('ss.options.state.hide'), 'hide'],
    ]
  end

  def validate_destination_filename(dst)
    dst_dir = ::File.dirname(dst).sub(/^\.$/, "")
    (@cur_site || site).then do |s|
      return errors.add :filename, :empty if dst.blank?
      return errors.add :filename, :invalid if dst !~ /^([\w\-]+\/)*[\w\-]+(#{::Regexp.escape(fix_extname || "")})?$/

      return errors.add :base, :same_filename if filename == dst
      return errors.add :filename, :taken if Cms::Node.site(s).where(filename: dst).first
      return errors.add :base, :exist_physical_file if Fs.exist?("#{s.path}/#{dst}")

      if dst_dir.present?
        dst_parent = Cms::Node.site(s).where(filename: dst_dir).first

        return errors.add :base, :not_found_parent_node if dst_parent.blank?
        return errors.add :base, :subnode_of_itself if filename == dst_parent.filename

        allowed = dst_parent.allowed?(:read, @cur_user, site: s)
        return errors.add :base, :not_have_parent_read_permission unless allowed
      end
    end
  end

  def move(dst)
    validate_destination_filename(dst)
    return false unless errors.empty?

    src = url
    self.cur_node = nil
    self.filename = dst
    self.basename = nil
    result = save
    if result && SS.config.cms.replace_urls_after_move
      Cms::Page::MoveJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later(src: src, dst: url)
    end
    result
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

  def remove_files_recursively?
    return false if skip_remove_files_recursively
    return true if @db_changes && @db_changes["state"] && !public?
    return true if @db_changes && @db_changes["route"] && public?
    false
  end

  def remove_files_recursively
    remove_owned_files
    remove_children_recursively
  end

  def update_page_index_queues
    site = @cur_site || self.site
    return if site.blank?
    return unless site.elasticsearch_enabled?

    if public? && public_node?
      Cms::Elasticsearch::Indexer::NodeReleaseJob.bind(site_id: site, node_id: id).perform_later
    else
      Cms::Elasticsearch::Indexer::NodeCloseJob.bind(site_id: site, node_id: id).perform_later
    end
  end

  def remove_all
    dst = path.sub("#{Rails.root}/public", History::Trash.root)
    Fs.rm_rf(dst) if Fs.exist?(dst)
    Fs.mkdir_p(File.dirname(dst))
    Fs.mv(path, dst) if Fs.exist?(path)
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

  def validate_ancestors
    return if route.start_with?('uploader/')

    p = parent
    while p
      if p.route.start_with?('uploader/')
        errors.add(:base, :routed_folders_under_uploader)
        break
      end
      p = p.parent
    end
  end

  def rename_children
    return unless @db_changes["filename"]
    return unless @db_changes["filename"][0]

    src = "#{(@cur_site || site).path}/#{@db_changes['filename'][0]}"
    dst = "#{(@cur_site || site).path}/#{@db_changes['filename'][1]}"
    dst_dir = ::File.dirname(dst)

    Fs.mkdir_p dst_dir unless Fs.exist?(dst_dir)
    Fs.mv src, dst if Fs.exist?(src)

    src, dst = @db_changes["filename"]
    [ Cms::Node, Cms::Page, Cms::Part, Cms::Layout ].each do |model|
      criteria = model.unscoped
      criteria = criteria.site(@cur_site || site)
      criteria = criteria.where(filename: /^#{::Regexp.escape(src)}\//)

      all_ids = criteria.pluck(:id)
      all_ids.each_slice(20) do |ids|
        criteria.in(id: ids).to_a.each do |item|
          dst_filename = item.filename.sub(/^#{::Regexp.escape(src)}\//, "#{dst}/")
          item.set(filename: dst_filename, depth: dst_filename.scan("/").size + 1)
        end
      end
    end
  end

  def destroy_children
    %w(nodes pages parts layouts).each do |name|
      send(name).each do |item|
        item.cur_user = @cur_user
        item.destroy
      end
    end
  end

  def template_variable_handler_pages_count(name, issuer)
    date = issuer.try(:cur_date) || Time.zone.now
    criteria = Cms::Page.site(issuer.cur_site || issuer.site)
    criteria = criteria.and_public(date)
    criteria = criteria.where("$or" => [
      { filename: /^#{::Regexp.escape(filename)}\//, depth: depth + 1 },
      { category_ids: id }
    ])
    criteria.count.to_s
  end

  def remove_owned_files
    return if !Dir.exist?(path)

    Dir.foreach(path) do |name|
      next if name == '.' || name == '..'

      fullname = "#{path}/#{name}"
      next if File::ftype(fullname) != 'file'
      File.delete(fullname)
    end
  end

  def remove_children_recursively
    children.each do |child_node|
      child_node.remove_files_recursively
    end
  end
end
