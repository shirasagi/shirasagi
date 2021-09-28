module SS::Model::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::FileFactory
  include SS::ExifGeoLocation
  include SS::CsvHeader
  include SS::FileUsageAggregation
  include SS::UploadPolicy
  include History::Addon::Trash
  include ActiveSupport::NumberHelper

  attr_accessor :in_file, :resizing, :disable_image_resizes

  included do
    store_in collection: "ss_files"

    seqid :id
    field :model, type: String
    field :state, type: String, default: "closed"
    field :name, type: String
    field :filename, type: String
    field :size, type: Integer
    field :content_type, type: String

    belongs_to :site, class_name: "SS::Site"

    belongs_to :owner_item, class_name: "Object", polymorphic: true

    attr_accessor :in_data_url

    permit_params :in_file, :state, :name, :filename, :resizing, :disable_image_resizes, :in_data_url

    before_validation :set_filename, if: ->{ in_file.present? }
    before_validation :normalize_name
    before_validation :normalize_filename

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validates :content_type, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validate :validate_filename, if: ->{ filename.present? }
    validate :validate_upload_policy, if: ->{ in_file.present? }
    validates_with SS::FileSizeValidator, if: ->{ size.present? }

    before_save :mangle_filename
    before_save :rename_file, if: ->{ @db_changes.present? }
    before_save :save_file
    before_destroy :remove_file

    default_scope ->{ order_by name: 1 }

    if Rails.env.test?
      define_method(:url) { SS.config.ss.file_url_with == "name" ? url_with_name : url_with_filename }
      define_method(:full_url) { SS.config.ss.file_url_with == "name" ? full_url_with_name : full_url_with_filename }
    elsif SS.config.ss.file_url_with == "name"
      define_method(:url) { url_with_name }
      define_method(:full_url) { full_url_with_name }
    else
      define_method(:url) { url_with_filename }
      define_method(:full_url) { full_url_with_filename }
    end
  end

  module ClassMethods
    def root
      "#{SS::Application.private_root}/files"
    end

    def resizing_options
      [
        [320, 240], [240, 320], [640, 480], [480, 640], [800, 600], [600, 800],
        [1024, 768], [768, 1024], [1280, 720], [720, 1280]
      ].map { |x, y| [I18n.t("ss.options.resizing.#{x}x#{y}"), "#{x},#{y}"] }
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :filename
      end
      criteria
    end
  end

  def path
    "#{self.class.root}/ss_files/" + id.to_s.split(//).join("/") + "/_/#{id}"
  end

  def public_dir
    return if site.blank? || !site.respond_to?(:root_path)
    "#{site.root_path}/fs/" + id.to_s.split(//).join("/") + "/_"
  end

  def public_path
    public_dir.try { |dir| "#{dir}/#{filename}" }
  end

  def url_with_filename
    "/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
  end

  def url_with_name
    if SS::FilenameUtils.url_safe_japanese?(name)
      "/fs/" + id.to_s.split(//).join("/") + "/_/#{Addressable::URI.encode_component(name)}"
    else
      url_with_filename
    end
  end

  def full_url_with_filename
    return if site.blank? || !site.respond_to?(:full_root_url)
    "#{site.full_root_url}fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
  end

  def full_url_with_name
    return if site.blank? || !site.respond_to?(:full_root_url)
    if SS::FilenameUtils.url_safe_japanese?(name)
      "#{site.full_root_url}fs/" + id.to_s.split(//).join("/") + "/_/#{Addressable::URI.encode_component(name)}"
    else
      full_url_with_filename
    end
  end

  def thumb_url
    "/fs/" + id.to_s.split(//).join("/") + "/_/thumb/#{filename}"
  end

  def public?
    state == "public"
  end

  def becomes_with_model
    klass = SS::File.find_model_class(model)
    return self unless klass

    becomes_with(klass)
  end

  def previewable?(opts = {})
    meta = SS::File.find_model_metadata(model) || {}

    # be careful: cur_user and item may be nil
    cur_user = opts[:user]
    cur_member = opts[:member]
    item = effective_owner_item
    if cur_user && item
      permit = meta[:permit] || %i(role readable member)
      if permit.include?(:readable) && item.respond_to?(:readable?)
        return true if item.readable?(cur_user, site: item.try(:site))
      end
      if permit.include?(:member) && item.respond_to?(:member?)
        return true if item.member?(cur_user)
      end
      if permit.include?(:role) && item.respond_to?(:allowed?)
        return true if item.allowed?(:read, cur_user, site: item.try(:site))
      end
    end

    if item && item.is_a?(Fs::FilePreviewable)
      # special delegation if item implements previewable?
      return true if item.file_previewable?(self, user: cur_user, member: cur_member)
    end

    if cur_user && respond_to?(:user_id)
      return true if user_id == cur_user.id
    end

    false
  end

  def state_options
    [[I18n.t('ss.options.state.public'), 'public']]
  end

  def name
    self[:name].presence || basename
  end

  def humanized_name
    "#{::File.basename(name, ".*")} (#{extname.upcase} #{number_to_human_size(size)})"
  end

  def download_filename
    return name if name.include?('.') && !name.end_with?(".")

    name_without_ext = ::File.basename(name, ".*")
    ext = ::File.extname(filename)
    return name_without_ext if ext.blank? || ext == "."

    name_without_ext + ext
  end

  def basename
    filename.present? ? ::File.basename(filename) : ""
  end

  def extname
    return "" if filename.blank?

    ret = ::File.extname(filename)
    return "" if ret.blank?

    ret = ret[1..-1] if ret.start_with?(".")
    ret
  end

  def image?
    to_io { |io| SS::ImageConverter.image?(io) }
  end

  def exif_image?
    to_io { |io| SS::ImageConverter.exif_image?(io) }
  end

  def viewable?
    image?
  end

  def resizing
    (@resizing && @resizing.size == 2) ? @resizing.map(&:to_i) : nil
  end

  def resizing=(size)
    @resizing = (size.class == String) ? size.split(",") : size
  end

  def read
    Fs.exists?(path) ? Fs.binread(path) : nil
  end

  def to_io(&block)
    Fs.exists?(path) ? Fs.to_io(path, &block) : nil
  end

  def uploaded_file(&block)
    Fs::UploadedFile.create_from_file(self, filename: basename, content_type: content_type, fs_mode: ::Fs.mode, &block)
  end

  def generate_public_file
    dir = public_dir
    return if dir.blank?

    SS::FilePublisher.publish(self, dir)
  end

  def remove_public_file
    dir = public_dir
    return if dir.blank?

    SS::FilePublisher.depublish(self, dir)
  end

  COPY_SKIP_ATTRS = %w(_id id model file_id group_ids permission_level category_ids owner_item_id owner_item_type).freeze

  def copy(opts = {})
    model = opts[:cur_node].present? ? Cms::TempFile : SS::TempFile
    model = opts[:model].constantize if opts[:model].present?

    copy_attrs = {}
    self.attributes.each do |key, val|
      next if COPY_SKIP_ATTRS.include?(key)
      copy_attrs[key] = val if model.fields.key?(key)
    end

    # forcibly overwrite by opts
    copy_attrs["site"] = opts[:cur_site] if opts[:cur_site].present?
    if opts[:cur_user].present?
      copy_attrs["cur_user"] = opts[:cur_user]
      copy_attrs["user"] = opts[:cur_user]
    end
    if opts[:cur_node].present?
      copy_attrs["cur_node"] = opts[:cur_node]
      copy_attrs["node"] = opts[:cur_node]
    end
    if opts[:copy_attrs].present?
      copy_attrs.merge!(opts[:copy_attrs])
    end

    model.create_empty!(copy_attrs) do |new_file|
      ::FileUtils.copy(self.path, new_file.path)
      # to create thumbnail call "#save!"
      new_file.save!
      new_file.sanitizer_copy_file
    end
  end

  COPY_REQUIRED_MODELS = %w(cms/file ss/user_file).freeze

  def copy_if_necessary(opts = {})
    return self if !COPY_REQUIRED_MODELS.include?(self.model)
    copy(opts)
  end

  def image_dimension
    return unless Fs.exists?(path)
    return unless image?

    ::FastImage.size(path) rescue nil
  end

  def shrink_image_to(width, height)
    return false unless image?

    cur_width, cur_height = image_dimension
    return false if cur_width.nil? || cur_height.nil?
    return true if cur_width <= width && cur_height <= height

    SS::ImageConverter.open(path) do |converter|
      converter.resize_to_fit!(width, height)
      ::Fs.upload(path, converter.to_io)
    end

    self.update(size: ::Fs.size(path))
    true
  end

  private

  def effective_owner_item
    item = owner_item rescue nil
    return item if item.present?

    type = @item.model.camelize.constantize rescue nil
    return if type.blank?

    conds = (type.fields.keys & %w(file_id file_ids)).map { |f| { f => id} }
    type.where("$and" => [{ "$or" => conds }]).first
  end

  def set_filename
    self.name         = in_file.original_filename if self[:name].blank?
    self.filename     = in_file.original_filename if filename.blank?
    self.size         = in_file.size
    self.content_type = ::SS::MimeType.find(in_file.original_filename, in_file.content_type)
  end

  def normalize_name
    self.name = SS::FilenameUtils.convert_to_url_safe_japanese(name) if self.name.present?
  end

  def normalize_filename
    self.filename = SS::FilenameUtils.normalize(self.filename)
  end

  def multibyte_filename_disabled?
    return if site.blank? || !site.respond_to?(:multibyte_filename_disabled?)
    site.multibyte_filename_disabled?
  end

  def validate_filename
    if multibyte_filename_disabled? && filename !~ /^\/?([\w\-]+\/)*[\w\-]+\.[\w\-\.]+$/
      errors.add :base, :invalid_filename
    end
  end

  def mangle_filename
    set_sequence
    self.filename = SS::FilenameUtils.convert(filename, id: id)
  end

  def save_file
    errors.add :in_file, :blank if new_record? && in_file.blank?
    return false if errors.present?
    return if in_file.blank?

    if csv_or_xlsx?
      extract_csv_headers(in_file)
      in_file.rewind
    end

    dir = ::File.dirname(path)
    Fs.mkdir_p(dir) unless Fs.exists?(dir)

    SS::ImageConverter.attach(in_file, ext: ::File.extname(in_file.original_filename)) do |converter|
      converter.apply_defaults!(resizing: resizing_with_max_file_size, quality: quality)
      Fs.upload(path, converter.to_io)
      self.geo_location = converter.geo_location
    end

    sanitizer_save_file

    self.size = Fs.size(path)
  end

  def create_history_trash
    return if model.to_s.include?('temp_file') || model.to_s.include?('thumb_file')
    return if owner_item_type.to_s.start_with?('Gws', 'Sns', 'SS', 'Sys', 'Webmail')

    backup = History::Trash.new
    backup.ref_coll = collection_name
    backup.ref_class = self.class.to_s
    backup.data = attributes
    backup.site = self.site
    backup.user = @cur_user
    return unless backup.save
    return unless File.exists?(path)
    trash_path = "#{History::Trash.root}/#{path.sub(/.*\/(ss_files\/)/, '\\1')}"
    FileUtils.mkdir_p(File.dirname(trash_path))
    FileUtils.cp(path, trash_path)
  end

  def remove_file
    Fs.rm_rf(path)
    remove_public_file
  end

  def rename_file
    return unless @db_changes["filename"]
    return unless @db_changes["filename"][0]

    remove_public_file if site
  end

  def resizing_with_max_file_size
    size = resizing || []
    max_file_sizes = []
    if user.blank? || !SS::ImageResize.allowed?(:disable, user) || disable_image_resizes.blank?
      max_file_sizes << SS::ImageResize.find_by_ext(extname)
    end
    if self.class.include?(Cms::Reference::Node) && node.present?
      if user.blank? || !Cms::ImageResize.allowed?(:disable, user, site: site, node: node) || disable_image_resizes.blank?
        max_file_sizes << Cms::ImageResize.site(site).node(node).find_by_ext(extname)
      end
    end
    max_file_sizes.reject(&:blank?).each do |max_file_size|
      if size.present?
        max_file_size.max_width = size[0] if max_file_size.max_width > size[0]
        max_file_size.max_height = size[1] if max_file_size.max_height > size[1]
      end
      size = [max_file_size.max_width, max_file_size.max_height]
    end
    size
  end

  def quality
    quality = []
    max_file_sizes = []
    if user.blank? || !SS::ImageResize.allowed?(:disable, user) || disable_image_resizes.blank?
      max_file_sizes << SS::ImageResize.find_by_ext(extname)
    end
    if self.class.include?(Cms::Reference::Node) && node.present?
      if user.blank? || !Cms::ImageResize.allowed?(:disable, user, site: site, node: node) || disable_image_resizes.blank?
        max_file_sizes << Cms::ImageResize.site(site).node(node).find_by_ext(extname)
      end
    end
    max_file_sizes.reject(&:blank?).each do |max_file_size|
      next if size <= max_file_size.try(:size)
      quality << max_file_size.try(:quality)
    end
    quality.reject(&:blank?).min
  end
end
