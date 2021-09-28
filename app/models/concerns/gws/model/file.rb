module Gws::Model::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::FileFactory
  include SS::ExifGeoLocation
  include SS::UploadPolicy
  include SS::CsvHeader
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

    attr_accessor :in_data_url

    permit_params :in_file, :state, :name, :filename, :resizing, :disable_image_resizes, :in_data_url

    before_validation :set_filename, if: ->{ in_file.present? }
    before_validation :normalize_name
    before_validation :normalize_filename

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validates :content_type, presence: true
    validate :validate_filename, if: -> { filename.present? }
    validate :validate_upload_policy, if: ->{ in_file.present? }
    validates_with SS::FileSizeValidator, if: ->{ size.present? }

    before_save :mangle_filename
    before_save :rename_file, if: ->{ @db_changes.present? }
    before_save :save_file
    before_destroy :remove_file

    define_model_callbacks :_save_file

    default_scope ->{ order_by id: -1 }
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

  def url
    "/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
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
    cur_user = opts[:user]
    cur_user.present?
  end

  def state_options
    [[I18n.t('ss.options.state.public'), 'public']]
  end

  def name
    self[:name].presence || basename
  end

  def humanized_name
    "#{name.sub(/\.[^\.]+$/, '')} (#{extname.upcase} #{number_to_human_size(size)})"
  end

  def download_filename
    name.include?('.') ? name : "#{name}.#{extname}"
  end

  def basename
    filename.to_s.sub(/.*\//, "")
  end

  def extname
    return "" unless filename.to_s.include?('.')

    filename.to_s.sub(/.*\W/, "")
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

  private

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
      errors.add :in_file, :invalid_filename
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

    run_callbacks(:_save_file) do
      SS::ImageConverter.attach(in_file, ext: ::File.extname(in_file.original_filename)) do |converter|
        converter.apply_defaults!(resizing: resizing_with_max_file_size, quality: quality)
        Fs.upload(path, converter.to_io)
        self.geo_location = converter.geo_location
      end

      sanitizer_save_file

      self.size = Fs.size(path)
    end
  end

  def remove_file
    Fs.rm_rf(path)
    Dir.glob(path + "_history[0-9]*").each { |file| Fs.rm_rf(file) } if Dir.glob(path + "_history[0-9]*").count > 0
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
    max_file_sizes.reject(&:blank?).each do |max_file_size|
      next if size <= max_file_size.try(:size)
      quality << max_file_size.try(:quality)
    end
    quality.reject(&:blank?).min
  end
end
