module SS::Model::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::Locatable
  include SS::ReadableFile
  include SS::FileFactory
  include SS::ExifGeoLocation
  include SS::CsvHeader
  include SS::FileUsageAggregation
  include SS::UploadPolicy
  include SS::VariantProcessor
  include History::Addon::Trash
  include ActiveSupport::NumberHelper

  attr_accessor :in_file, :resizing, :quality, :image_resizes_disabled

  included do
    store_in collection: "ss_files"

    seqid :id
    field :model, type: String
    field :state, type: String, default: "closed"
    field :name, type: String
    field :filename, type: String
    field :size, type: Integer, default: 0
    field :content_type, type: String

    belongs_to :site, class_name: "SS::Site"

    belongs_to :owner_item, class_name: "Object", polymorphic: true

    attr_accessor :in_data_url

    permit_params :in_file, :state, :name, :filename, :resizing, :quality, :image_resizes_disabled, :in_data_url

    before_validation :set_filename, if: ->{ in_file.present? }
    before_validation :normalize_attributes

    validates :model, presence: true
    validates :state, presence: true
    validates :name, presence: true
    validates :filename, presence: true
    validates :content_type, presence: true
    validate :validate_filename, if: ->{ filename.present? }
    validate :validate_upload_policy, if: ->{ in_file.present? }
    validates_with SS::FileSizeValidator, if: ->{ size.present? }

    before_save :mangle_filename
    before_save :rename_file, if: ->{ changes.present? || previous_changes.present? }
    before_save :save_file
    before_destroy :remove_file

    default_scope ->{ order_by name: 1 }
  end

  module ClassMethods
    def root
      "#{SS::Application.private_root}/files"
    end

    def image_resizes_min_attributes(opts = {})
      if opts[:user]
        disable_image_resizes = SS::ImageResize.allowed?(:disable, opts[:user]) &&
                                SS::ImageResize.where(state: SS::ImageResize::STATE_ENABLED).present?
        if opts[:node]
          disable_image_resizes ||=
            Cms::ImageResize.allowed?(:disable, opts[:user], site: opts[:node].site, node: opts[:node]) &&
            Cms::ImageResize.site(opts[:node].site).node(opts[:node]).where(state: SS::ImageResize::STATE_ENABLED).present?
        end
        return {} if disable_image_resizes
      end

      min_attributes = [SS::ImageResize.where(state: SS::ImageResize::STATE_ENABLED).min_attributes]
      if opts[:node]
        min_attributes << Cms::ImageResize.site(opts[:node].site).
          node(opts[:node]).
          where(state: SS::ImageResize::STATE_ENABLED).min_attributes
      end

      min_attributes.inject do |a, b|
        a.merge(b) do |k, v1, v2|
          next v1 if v2.blank?
          next v2 if v1.blank?

          [v1, v2].min
        end
      end
    end

    def resizing_options(opts = {})
      options = [
        [320, 240], [240, 320], [640, 480], [480, 640], [800, 600], [600, 800],
        [1024, 768], [768, 1024], [1280, 720], [720, 1280]
      ].map { |x, y| [I18n.t("ss.options.resizing.#{x}x#{y}"), "#{x},#{y}"] }

      return options unless opts[:user]

      min_width = image_resizes_min_attributes(opts)['max_width']
      min_height = image_resizes_min_attributes(opts)['max_height']

      return options if min_width.blank? || min_height.blank?

      options.select do |k, v|
        size = v.split(',').collect(&:to_i)
        size[0] <= min_width && size[1] <= min_height
      end
    end

    def quality_options(opts = {})
      options = SS.config.ss.quality_options.collect { |v| [ v['label'], v['quality'] ] } rescue []

      return options unless opts[:user]

      min_quality = image_resizes_min_attributes(user: opts[:user], node: opts[:node])['quality']

      return options unless min_quality

      options.select do |k, v|
        quality = v.to_i
        quality <= min_quality
      end
    end

    def image_resizes_disabled_options
      %w(enabled disabled).map { |value| [I18n.t("ss.options.image_resizes_disabled.#{value}"), value] }
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

  module Utils
    module_function

    def owned?(file, user)
      return false if !user
      return false if !file.respond_to?(:user_id)
      file.user_id == user.id
    end

    def previewable_by_owner?(file, owner_item, site:, user:, member:)
      return false if !owner_item
      return false if !owner_item.is_a?(Fs::FilePreviewable)
      owner_item.file_previewable?(file, site: site, user: user, member: member)
    end

    def cms_object?(_file, owner_item)
      owner_item.try(:site) && owner_item.site.is_a?(SS::Model::Site)
    end

    def same_cms_site?(file, owner_item, site:)
      return true if site.is_a?(SS::Model::Site) && owner_item.site.is_a?(SS::Model::Site) && site.id == owner_item.site_id
      false
    end

    def readable_by_user?(file, owner_item, user:)
      meta = SS::File.find_model_metadata(file.model) || {}
      permit = meta[:permit] || %i(role readable member)

      site = owner_item.try(:cur_site) || owner_item.try(:site)
      if permit.include?(:readable) && owner_item.respond_to?(:readable?) && owner_item.readable?(user, site: site)
        return true
      end
      if permit.include?(:member) && owner_item.respond_to?(:member?) && owner_item.member?(user)
        return true
      end
      if permit.include?(:role) && owner_item.respond_to?(:allowed?) && owner_item.allowed?(:read, user, site: site)
        return true
      end

      false
    end

    def fs_access_allowed?(file, owner_item, request)
      # 現在 /fs 以下のアクセス制限が可能なのは CMS のみ。CMS 以外のオブジェクトについては常にアクセスを許可する。
      return true unless Utils.cms_object?(file, owner_item)
      # /fs 以下のアクセスが制限されていない場合はアクセスを許可する。
      return true unless owner_item.site.file_fs_access_restricted?

      owner_item.site.file_fs_access_allowed?(request)
    end
  end

  def public?
    state == "public"
  end

  def becomes_with_model
    klass = SS::File.find_model_class(model)
    return self unless klass

    becomes_with(klass)
  end

  def previewable?(site: nil, user: nil, member: nil)
    # be careful: cur_user and item may be nil
    item = effective_owner_item
    if site && Utils.cms_object?(self, item) && !Utils.same_cms_site?(self, item, site: site)
      Rails.logger.warn { "file is requested in different site" }
      return false
    end
    unless Utils.fs_access_allowed?(self, item, Rails.application.current_request)
      Rails.logger.warn { "access to /fs is not allowed" }
      return false
    end
    if user && item && Utils.readable_by_user?(self, item, user: user)
      return true
    end

    return true if Utils.owned?(self, user)

    # special delegation if item implements previewable?
    return true if Utils.previewable_by_owner?(self, item, site: site, user: user, member: member)

    Rails.logger.warn { "file access is not allowed" }
    false
  end

  def state_options
    [[I18n.t('ss.options.state.public'), 'public']]
  end

  def humanized_name
    "#{::File.basename(name, ".*")} (#{extname.upcase} #{number_to_human_size(size)})"
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
    @resizing = size.instance_of?(String) ? size.split(",") : size
  end

  def uploaded_file(&block)
    Fs::UploadedFile.create_from_file(self, filename: basename, content_type: content_type, fs_mode: ::Fs.mode, &block)
  end

  def generate_public_file
    if site && site.try(:file_fs_access_restricted?)
      remove_public_file
      return
    end

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
      new_file.sanitizer_copy_file
    end
  end

  COPY_REQUIRED_MODELS = %w(cms/file ss/user_file).freeze

  def copy_if_necessary(opts = {})
    return self if !COPY_REQUIRED_MODELS.include?(self.model)
    copy(opts)
  end

  def image_dimension
    return unless Fs.exist?(path)
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
    return if in_file.blank?
    return if filename.present?

    self.filename = in_file.original_filename
  end

  def normalize_attributes
    # name
    self.name = filename if name.blank? && filename.present?
    if (new_record? || name_changed?) && name.present?
      self.name = SS::FilenameUtils.convert_to_url_safe_japanese(name)
    end

    # filename
    if (new_record? || filename_changed?) && filename.present?
      self.filename = SS::FilenameUtils.normalize(filename)
    end

    # content_type
    self.content_type = SS::MimeType.find(filename) if filename.present?
  end

  def multibyte_filename_disabled?
    return if site.blank? || !site.respond_to?(:multibyte_filename_disabled?)
    site.multibyte_filename_disabled?
  end

  def validate_filename
    if multibyte_filename_disabled? && filename !~ /^\/?([\w\-]+\/)*[\w\-]+\.[\w\-.]+$/
      errors.add :base, :invalid_filename
    end
  end

  def mangle_filename
    if new_record? || filename_changed?
      set_sequence
      self.filename = SS::FilenameUtils.convert(filename, id: id)
    end
  end

  def save_file
    return false if errors.present?
    return if in_file.blank?

    if csv_or_xlsx?
      extract_csv_headers(in_file)
      in_file.rewind
    end

    dir = ::File.dirname(path)
    Fs.mkdir_p(dir) unless Fs.exist?(dir)

    SS::ImageConverter.attach(in_file, ext: ::File.extname(filename)) do |converter|
      converter.apply_defaults!(resizing: resizing_with_max_file_size, quality: quality_with_max_file_size)
      Fs.upload(path, converter.to_io)
      self.geo_location = converter.geo_location
    end
    self.size = Fs.size(path)

    if SS::SvgSanitizer.sanitize(self.path, content_type: self.content_type)
      self.size = ::Fs.size(self.path)
    end

    update_variants if respond_to?(:update_variants)
    sanitizer_save_file
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
    return unless File.exist?(path)
    trash_path = "#{History::Trash.root}/#{path.sub(/.*\/(ss_files\/)/, '\\1')}"
    FileUtils.mkdir_p(File.dirname(trash_path))
    FileUtils.cp(path, trash_path)
  end

  def remove_file
    Fs.rm_rf(path)
    Fs.rm_rf("#{path}_thumb")
    remove_public_file
  end

  def rename_file
    return if new_record?
    return if !filename_changed? && !name_changed?
    remove_public_file if site
  end

  def max_file_sizes
    max_file_sizes = []
    if user.blank? || !SS::ImageResize.allowed?(:disable, user) || image_resizes_disabled != 'disabled'
      max_file_sizes += SS::ImageResize.where(state: SS::ImageResize::STATE_ENABLED).to_a
    end
    if self.class.include?(Cms::Reference::Node) && node.present?
      cms_image_resizes_enabled = user.blank? ||
                                  !Cms::ImageResize.allowed?(:disable, user, site: site, node: node) ||
                                  image_resizes_disabled != 'disabled'
      if cms_image_resizes_enabled
        max_file_sizes += Cms::ImageResize.site(site).node(node).where(state: SS::ImageResize::STATE_ENABLED).to_a
      end
    end
    max_file_sizes.reject(&:blank?)
  end

  def resizing_with_max_file_size
    size = resizing || []
    max_file_sizes.each do |max_file_size|
      if size.present?
        max_file_size.max_width = size[0] if max_file_size.max_width > size[0]
        max_file_size.max_height = size[1] if max_file_size.max_height > size[1]
      end
      size = [max_file_size.max_width, max_file_size.max_height]
    end
    size
  end

  def quality_with_max_file_size
    quality = []
    quality << self.quality.try(:to_i) if self.quality.present?
    max_file_sizes.each do |max_file_size|
      next if size <= max_file_size.try(:size)
      quality << max_file_size.try(:quality)
    end
    quality.reject(&:blank?).min
  end
end
