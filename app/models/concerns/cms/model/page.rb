module Cms::Model::Page
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::Reference::Layout

  included do
    class_variable_set(:@@_after_generate_file_callbacks, [])
    class_variable_set(:@@_after_remove_file_callbacks, [])
    class_variable_set(:@@_after_rename_file_callbacks, [])

    store_in collection: "cms_pages"
    set_permission_name "cms_pages"

    #text_index :name, :html

    field :route, type: String, default: ->{ "cms/page" }

    embeds_ids :categories, class_name: "Cms::Node"

    permit_params category_ids: []

    after_validation :set_released, if: -> { public? }
    after_save :rename_file, if: ->{ @db_changes }
    after_save :generate_file, if: ->{ @db_changes }
    after_save :remove_file, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_destroy :remove_file

    template_variable_handler(:categories, :template_variable_handler_categories)
  end

  def date
    released || super
  end

  def generate_file
    return false unless serve_static_file?
    return false unless public?
    return false unless public_node?
    written = Cms::Agents::Tasks::PagesController.new.generate_page(self)
    self.class.class_variable_get(:@@_after_generate_file_callbacks).each do |c|
      run_callback(c)
    end
    written
  end

  def remove_file
    Fs.rm_rf path
    self.class.class_variable_get(:@@_after_remove_file_callbacks).each do |c|
      run_callback(c)
    end
  end

  def rename_file
    return unless @db_changes["filename"]
    return unless @db_changes["filename"][0]

    src = "#{site.path}/#{@db_changes['filename'][0]}"
    dst = "#{site.path}/#{@db_changes['filename'][1]}"
    dst_dir = ::File.dirname(dst)

    Fs.mkdir_p dst_dir unless Fs.exists?(dst_dir)
    Fs.mv src, dst if Fs.exists?(src)
    self.class.class_variable_get(:@@_after_rename_file_callbacks).each do |c|
      run_callback(c, src, dst)
    end
  end

  def validate_destination_filename(dst)
    dst_dir = ::File.dirname(dst).sub(/^\.$/, "")

    return errors.add :filename, :empty if dst.blank?
    return errors.add :filename, :invalid if dst !~ /^([\w\-]+\/)*[\w\-]+(#{Regexp.escape(fix_extname)})?$/
    return errors.add :base, :branch_page_can_not_move if self.try(:branch?)

    return errors.add :base, :same_filename if filename == dst
    return errors.add :filename, :taken if self.class.where(site_id: site_id, filename: dst).first
    return errors.add :base, :exist_physical_file if Fs.exists?("#{site.path}/#{dst}")

    if dst_dir.present?
      dst_parent = Cms::Node.where(site_id: site_id, filename: dst_dir).first

      return errors.add :base, :not_found_parent_node if dst_parent.blank?

      allowed = dst_parent.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
      return errors.add :base, :not_have_parent_read_permission unless allowed
    elsif route != "cms/page"
      return errors.add :base, :not_cms_page_in_root
    end
  end

  def move(dst)
    validate_destination_filename(dst)
    if is_a?(Cms::Addon::EditLock)
      errors.add :base, :locked, user: lock_owner.long_name if locked?
    end
    return false unless errors.empty?

    @cur_node = nil
    @basename = dst
    if is_a?(Cms::Addon::EditLock)
      remove_attribute(:lock_owner_id) if has_attribute?(:lock_owner_id)
      remove_attribute(:lock_until) if has_attribute?(:lock_until)
    end
    save
  end

  # returns admin side show path
  def private_show_path(*args)
    model = self.class.name.underscore.sub(/^.+?\//, "")
    options = args.extract_options!
    methods = []
    if parent.blank?
      options = options.merge(site: site || cur_site, id: self)
      methods << "cms_#{model}_path"
    else
      options = options.merge(site: site || cur_site, cid: parent, id: self)
      if respond_to?(:route)
        route = self.route
        route = route =~ /cms\// ? "node_page" : route.tr("/", "_")
        methods << "#{route}_path"
      end
      methods << "node_#{model}_path"
    end

    helper_mod = Rails.application.routes.url_helpers
    methods.each do |method|
      path = helper_mod.send(method, *args, options) rescue nil
      return path if path.present?
    end

    nil
  end

  private
    def run_callback(c, *args)
      call = true
      call = instance_exec(&c[:if]) if c[:if]
      call = !instance_exec(&c[:unless]) if c[:unless]
      send(c[:method], *args) if call
    end

    def set_released
      self.released ||= Time.zone.now
    end

    def fix_extname
      ".html"
    end

    def template_variable_handler_categories(name, issuer)
      ret = categories.map do |category|
        html = "<span class=\"#{category.filename.tr('/', '-')}\">"
        html << "<a href=\"#{category.url}\">#{ERB::Util.html_escape(category.name)}</a>"
        html << "</span>"
        html
      end
      ret.join("\n").html_safe
    end

  module ClassMethods
    def after_generate_file(method, opts = {})
      callback = opts.merge(method: method)
      callbacks = class_variable_get(:@@_after_generate_file_callbacks)
      class_variable_set(:@@_after_generate_file_callbacks, callbacks << callback)
    end

    def after_remove_file(method, opts = {})
      callback = opts.merge(method: method)
      callbacks = class_variable_get(:@@_after_remove_file_callbacks)
      class_variable_set(:@@_after_remove_file_callbacks, callbacks << callback)
    end

    def after_rename_file(method, opts = {})
      callback = opts.merge(method: method)
      callbacks = class_variable_get(:@@_after_rename_file_callbacks)
      class_variable_set(:@@_after_rename_file_callbacks, callbacks << callback)
    end
  end
end
