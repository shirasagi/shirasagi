module SS::Model::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::FileFactory
  include SS::ExifGeoLocation
  include SS::FileUsageAggregation
  include History::Addon::Trash
  include ActiveSupport::NumberHelper

  attr_accessor :in_file, :resizing, :unnormalize

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

    permit_params :in_file, :state, :name, :filename, :resizing, :in_data_url

    before_validation :set_filename, if: ->{ in_file.present? }
    before_validation :normalize_filename, if: -> { !unnormalize }

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validates :content_type, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validate :validate_filename, if: ->{ filename.present? }
    validates_with SS::FileSizeValidator, if: ->{ size.present? }

    before_save :mangle_filename
    before_save :rename_file, if: ->{ @db_changes.present? }
    before_save :save_file
    before_destroy :remove_file

    default_scope ->{ order_by name: 1 }
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

  def public_path
    return if site.blank? || !site.respond_to?(:root_path)
    "#{site.root_path}/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
  end

  def url
    "/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
  end

  def download_url
    "/fs/" + id.to_s.split(//).join("/") + "/_/download/#{filename}"
  end

  def view_url
    "/fs/" + id.to_s.split(//).join("/") + "/_/view/#{filename}"
  end

  def full_url
    return if site.blank? || !site.respond_to?(:full_root_url)
    "#{site.full_root_url}fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
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
    return name_without_ext if ext.blank?

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
    content_type.to_s.start_with?('image/')
  end

  def exif_image?
    image? && filename =~ /\.(jpe?g|tiff?)$/i
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

  def to_io
    Fs.exists?(path) ? Fs.to_io(path) : nil
  end

  def uploaded_file(&block)
    Fs::UploadedFile.create_from_file(self, filename: basename, content_type: content_type, fs_mode: ::Fs.mode, &block)
  end

  def generate_public_file
    return if site.blank?
    return if !basename.ascii_only?
    return if Fs.exists?(public_path) && Fs.cmp(path, public_path)

    Fs.mkdir_p(::File.dirname(public_path))
    Fs.cp(path, public_path)
  end

  def remove_public_file
    Fs.rm_rf(public_path) if public_path
  end

  COPY_SKIP_ATTRS = %w(_id id model file_id group_ids permission_level category_ids owner_item_id owner_item_type).freeze

  def copy(opts = {})
    model = opts[:cur_node].present? ? Cms::TempFile : SS::TempFile

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

    model.create_empty!(copy_attrs) do |new_file|
      ::FileUtils.copy(self.path, new_file.path)
      new_file.unnormalize = true if opts[:unnormalize].present?
      # to create thumbnail call "#save!"
      new_file.save!
    end
  end

  COPY_REQUIRED_MODELS = %w(cms/file ss/user_file).freeze

  def copy_if_necessary(opts = {})
    return self if !COPY_REQUIRED_MODELS.include?(self.model)
    copy(opts)
  end

  def image_dimension
    return unless image?

    list = Magick::ImageList.new(path)
    max_width = 0
    max_height = 0
    list.each do |image|
      max_width = image.columns if max_width < image.columns
      max_height = image.rows if max_height < image.rows
    end

    [ max_width, max_height ]
  end

  def shrink_image_to(width, height)
    return false unless image?

    cur_width, cur_height = image_dimension
    return false if cur_width.nil? || cur_height.nil?
    return true if cur_width <= width && cur_height <= height

    return false unless SS::ImageConverter.resize_to_fit(self, width, height)

    self.update(size: ::File.size(path))
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

  def normalize_filename
    self.name     = self.name.unicode_normalize(:nfkc) if self.name.present?
    self.filename = self.filename.unicode_normalize(:nfkc) if self.filename.present?
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

    if image?
      list = Magick::ImageList.new
      list.from_blob(in_file.read)
      extract_geo_location(list) if exif_image?
      list.each do |image|
        if exif_image?
          case SS.config.env.image_exif_option
          when "auto_orient"
            image.auto_orient!
          when "strip"
            image.strip!
          end
        end

        next unless resizing
        width, height = resizing
        image.resize_to_fit! width, height if image.columns > width || image.rows > height
      end
      binary = list.to_blob
    else
      binary = in_file.read
    end
    in_file.rewind

    dir = ::File.dirname(path)
    Fs.mkdir_p(dir) unless Fs.exists?(dir)
    Fs.binwrite(path, binary)
    self.size = binary.length
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
end
