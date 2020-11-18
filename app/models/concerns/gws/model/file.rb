module Gws::Model::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::FileFactory
  include SS::ExifGeoLocation
  include ActiveSupport::NumberHelper

  attr_accessor :in_file, :resizing

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

    permit_params :in_file, :state, :name, :filename, :resizing, :in_data_url

    before_validation :set_filename, if: ->{ in_file.present? }
    before_validation :normalize_filename

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validates :content_type, presence: true
    validate :validate_filename, if: -> { filename.present? }
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

  def uploaded_file(&block)
    Fs::UploadedFile.create_from_file(self, filename: basename, content_type: content_type, fs_mode: ::Fs.mode, &block)
  end

  def generate_public_file
    return unless site && basename.ascii_only?

    file = public_path
    data = self.read
    return if Fs.exists?(file) && data == Fs.read(file)

    Fs.binwrite file, data
  end

  def remove_public_file
    Fs.rm_rf(public_path) if public_path
  end

  private

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

    run_callbacks(:_save_file) do
      Fs.binwrite(path, binary)
      self.size = binary.length
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
end
