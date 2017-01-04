module Cms::Model::Page
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::Reference::Layout

  included do
    define_model_callbacks :generate_file
    define_model_callbacks :remove_file
    define_model_callbacks :rename_file

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

  def preview_path
    site.subdir ?  "#{site.subdir}/#{filename}" : filename
  end

  def generate_file
    return false unless serve_static_file?
    return false unless public?
    return false unless public_node?
    run_callbacks :generate_file do
      Cms::Agents::Tasks::PagesController.new.generate_page(self)
    end
  end

  def remove_file
    run_callbacks :remove_file do
      Fs.rm_rf path
    end
  end

  def rename_file
    return unless @db_changes["filename"]
    return unless @db_changes["filename"][0]

    src = "#{site.path}/#{@db_changes['filename'][0]}"
    dst = "#{site.path}/#{@db_changes['filename'][1]}"
    dst_dir = ::File.dirname(dst)

    run_callbacks :rename_file do
      Fs.mkdir_p dst_dir unless Fs.exists?(dst_dir)
      Fs.mv src, dst if Fs.exists?(src)
    end
  end

  def validate_destination_filename(dst)
    dst_dir = ::File.dirname(dst).sub(/^\.$/, "")

    return errors.add :filename, :empty if dst.blank?
    return errors.add :filename, :invalid if dst !~ /^([\w\-]+\/)*[\w\-]+(#{Regexp.escape(fix_extname)})?$/
    return errors.add :base, :branch_page_can_not_move if self.try(:branch?)

    return errors.add :base, :same_filename if filename == dst
    return errors.add :filename, :taken if Cms::Page.site(site).where(filename: dst).first
    return errors.add :base, :exist_physical_file if Fs.exists?("#{site.path}/#{dst}")

    if dst_dir.present?
      dst_parent = Cms::Node.site(site).where(filename: dst_dir).first

      return errors.add :base, :not_found_parent_node if dst_parent.blank?

      allowed = dst_parent.allowed?(:read, @cur_user, site: @cur_site)
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

    self.cur_node = nil
    self.filename = dst
    self.basename = nil
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
    def set_released
      now = Time.zone.now
      self.released ||= now
      self.first_released ||= now
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

      p = self.parent
      if p.try(:category_node?)
        ret << begin
          html = "<span class=\"#{p.filename.tr('/', '-')}\">"
          html << "<a href=\"#{p.url}\">#{ERB::Util.html_escape(p.name)}</a>"
          html << "</span>"
          html
        end
      end

      ret.join("\n").html_safe
    end
end
