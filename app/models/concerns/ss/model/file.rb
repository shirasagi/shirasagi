module SS::Model::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  attr_accessor :in_file, :in_files, :resizing

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

    permit_params :state, :name, :filename
    permit_params :in_file, :in_files, in_files: []
    permit_params :resizing

    before_validation :set_filename, if: ->{ in_file.present? }
    before_validation :validate_filename, if: ->{ filename.present? }

    validates :model, presence: true
    validates :state, presence: true
    validates :filename, presence: true, if: ->{ in_file.blank? && in_files.blank? }
    validate :validate_size

    before_save :rename_file, if: ->{ @db_changes.present? }
    before_save :save_file
    before_destroy :remove_file
  end

  module ClassMethods
    def root
      "#{Rails.root}/private/files"
    end

    def resizing_options
      [
        [I18n.t('views.options.resizing.320×240'), "320,240"],
        [I18n.t('views.options.resizing.240x320'), "240,320"],
        [I18n.t('views.options.resizing.640x480'), "640,480"],
        [I18n.t('views.options.resizing.480x640'), "480,640"],
        [I18n.t('views.options.resizing.800x600'), "800,600"],
        [I18n.t('views.options.resizing.600x800'), "600,800"],
        [I18n.t('views.options.resizing.1024×768'), "1024,768"],
        [I18n.t('views.options.resizing.768x1024'), "768,1024"],
        [I18n.t('views.options.resizing.1280x720'), "1280,720"],
        [I18n.t('views.options.resizing.720x1280'), "720,1280"],
      ]
    end

    public
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

  public
    def path
      "#{self.class.root}/ss_files/" + id.to_s.split(//).join("/") + "/_/#{id}"
    end

    def public_path
      "#{site.path}/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
    end

    def url
      "/fs/" + id.to_s.split(//).join("/") + "/_/#{filename}"
    end

    def thumb_url
      "/fs/" + id.to_s.split(//).join("/") + "/_/thumb/#{filename}"
    end

    def public?
      state == "public"
    end

    def state_options
      [[I18n.t('views.options.state.public'), 'public']]
    end

    def name
      self[:name].presence || basename
    end

    def humanized_name
      "#{name} (#{extname.upcase} #{number_to_human_size(size)})"
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

    def save_files
      return false unless valid?

      in_files.each do |file|
        item = self.class.new(attributes)
        item.in_file = file
        item.resizing = resizing
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

  private
    def set_filename
      self.filename     = in_file.original_filename if filename.blank?
      self.size         = in_file.size
      self.content_type = ::SS::MimeType.find(in_file.original_filename, in_file.content_type)
    end

    def validate_filename
      self.filename = filename.gsub(/[^\w\-\.]/, "_")
    end

    def save_file
      errors.add :in_file, :blank if new_record? && in_file.blank?
      return false if errors.present?
      return if in_file.blank?

      if image? && resizing
        width, height = resizing
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

    def rename_file
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      remove_public_file if site
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
