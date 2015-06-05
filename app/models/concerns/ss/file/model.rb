module SS::File::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  attr_accessor :in_file, :in_files
  attr_accessor :image_size

  included do
    store_in collection: "ss_files"

    seqid :id
    field :model, type: String
    field :file_id, type: String
    field :state, type: String, default: "public"
    field :filename, type: String
    field :size, type: Integer
    field :content_type, type: String

    belongs_to :site, class_name: "SS::Site"

    permit_params :state, :filename
    permit_params :in_file, :in_files, in_files: []
    permit_params :image_size

    before_validation :set_filename, if: ->{ in_file.present? }

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ !in_file && !in_files }
    validate :validate_size

    before_save :save_file
    before_destroy :remove_file
  end

  module ClassMethods
    def root
      "#{Rails.root}/private/files"
    end

    def image_size_options
      [
        ["640x480(VGA)", "640,480"], ["480x640(VGA)", "480,640"],
        ["800x600(SVGA)", "800,600"], ["600x800(SVGA)", "600,800"],
        ["1024×768(XGA)", "1024,768"], ["768x1024(XGA)", "768,1024"],
        ["1280x720(HD)", "1280,720"], ["720x1280(HD)", "720,1280"]
      ]
    end
  end

  public
    def path
      "#{self.class.root}/ss_files/" + id.to_s.split(//).join("/") + "/_/#{id}"
    end

    def public_path
      "#{site.path}#{url}"
    end

    def state_options
      [[I18n.t('views.options.state.public'), 'public']]
    end

    def name
      filename
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

    def image_size
      (@image_size && @image_size.size == 2) ? @image_size.map(&:to_i) : nil
    end

    def image_size=(s)
      @image_size = (s.class == String) ? s.split(",") : s
    end

    def read
      Fs.exists?(path) ? Fs.binread(path) : nil
    end

    def save_files
      return false unless valid?

      in_files.each do |file|
        item = self.class.new(attributes)
        item.in_file = file
        item.image_size = image_size
        next if item.save

        item.errors.full_messages.each { |m| errors.add :base, m }
        return false
      end
      true
    end

    def uploaded_file
      file = Fs::UploadedFile.new("ss_file")
      file.binmode
      file.write(read)
      file.rewind
      file.original_filename = basename
      file.content_type = content_type
      file
    end

    def generate_public_file
      if site && basename.ascii_only?
        file = public_path
        data = self.read

        return if Fs.exists?(file) && data == Fs.read(file)
        Fs.binwrite file, data
      end
    end

    def remove_public_file
      Fs.rm_rf(public_path) if site
    end

    def url
      "/fs/#{id}/#{filename}"
    end

    def thumb_url
      "/fs/#{id}/thumb/#{filename}"
    end

  private
    def set_filename
      self.filename   ||= in_file.original_filename
      self.size         = in_file.size
      self.content_type = ::SS::MimeType.find(in_file.original_filename, in_file.content_type)
    end

    def save_file
      errors.add :in_file, :blank if new_record? && in_file.blank?
      return false if errors.present?
      return if in_file.blank?

      if image? && image_size
        width, height = image_size

        image = Magick::Image.from_blob(in_file.read).shift
        image = image.resize_to_fit width, height if image.columns > width || image.rows > height
        binary = image.to_blob
      else
        binary = in_file.read
      end

      dir = ::File.dirname(path)
      Fs.mkdir_p(dir) unless Fs.exists?(dir)
      Fs.binwrite(path, binary)
    end

    def remove_file
      Fs.rm_rf(path)
      remove_public_file
    end

    def validate_size
      validate_limit = lambda do |file|
        filename   = file.original_filename
        base_limit = SS.config.env.max_filesize
        ext_limit  = SS.config.env.max_filesize_ext[filename.sub(/.*\./, "").downcase]

        [ ext_limit, base_limit ].each do |limit|
          if limit.present? && file.size > limit
            errors.add :base, :too_large_file, filename: filename,
                       size: number_to_human_size(file.size),
                       limit: number_to_human_size(limit)
          end
        end
      end

      if in_file.present?
        validate_limit.call(in_file)
      elsif in_files.present?
        in_files.each { |file| validate_limit.call(file) }
      end
    end

    def number_to_human_size(size)
      ApplicationController.helpers.number_to_human_size(size)
    end
end
