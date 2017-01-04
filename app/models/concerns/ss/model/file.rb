module SS::Model::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include SS::FileFactory
  include SS::ExifGeoLocation
  include ActiveSupport::NumberHelper

  attr_accessor :in_file, :resizing

  included do
    cattr_accessor(:root, instance_accessor: false) { "#{Rails.root}/private/files" }
    store_in collection: "ss_files"

    seqid :id
    field :model, type: String
    field :state, type: String, default: "closed"
    field :name, type: String
    field :filename, type: String
    field :size, type: Integer
    field :content_type, type: String

    belongs_to :site, class_name: "SS::Site"

    permit_params :in_file, :state, :name, :filename, :resizing

    before_validation :set_filename, if: ->{ in_file.present? }

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validates_with SS::FileSizeValidator, if: ->{ size.present? }

    before_save :validate_filename
    before_save :rename_file, if: ->{ @db_changes.present? }
    before_save :save_file
    before_destroy :remove_file

    default_scope ->{ order_by id: -1 }
  end

  module ClassMethods
    def resizing_options
      [
        [320, 240], [240, 320], [640, 480], [480, 640], [800, 600], [600, 800],
        [1024, 768], [768, 1024], [1280, 720], [720, 1280]
      ].map { |x, y| [I18n.t("views.options.resizing.#{x}x#{y}"), "#{x},#{y}"] }
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
    "#{site.root_path}/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
  end

  def url
    "/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
  end

  def full_url
    "#{site.full_url}fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
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

    item = klass.new
    item.instance_variable_set(:@new_record, nil) unless new_record?
    instance_variables.each {|k| item.instance_variable_set k, instance_variable_get(k) }
    item
  end

  def previewable?(opts = {})
    cur_user = opts[:user]
    cur_user.present?
  end

  def state_options
    [[I18n.t('views.options.state.public'), 'public']]
  end

  def name
    self[:name].presence || basename
  end

  def humanized_name
    "#{name.sub(/\.[^\.]+$/, '')} (#{extname.upcase} #{number_to_human_size(size)})"
  end

  def download_filename
    name =~ /\./ ? name : name.sub(/\..*/, '') + extname
  end

  def basename
    filename.to_s.sub(/.*\//, "")
  end

  def extname
    filename.to_s.sub(/.*\W/, "")
  end

  def image?
    filename =~ /\.(bmp|gif|jpe?g|png)$/i
  end

  def resizing
    (@resizing && @resizing.size == 2) ? @resizing.map(&:to_i) : nil
  end

  def resizing=(s)
    @resizing = (s.class == String) ? s.split(",") : s
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
    Fs.rm_rf(public_path) if site #TODO: modify the trriger
  end

  private
    def set_filename
      self.name         = in_file.original_filename if self[:name].blank?
      self.filename     = in_file.original_filename if filename.blank?
      self.size         = in_file.size
      self.content_type = ::SS::MimeType.find(in_file.original_filename, in_file.content_type)
    end

    def validate_filename
      self.filename = SS::FilenameConvertor.convert(filename, id: id)
    end

    def save_file
      errors.add :in_file, :blank if new_record? && in_file.blank?
      return false if errors.present?
      return if in_file.blank?

      if image?
        list = Magick::ImageList.new
        list.from_blob(in_file.read)
        extract_geo_location(list)
        list.each do |image|
          case SS.config.env.image_exif_option
          when "auto_orient"
            image.auto_orient!
          when "strip"
            image.strip!
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
