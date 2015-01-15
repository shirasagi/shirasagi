module SS::File::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  attr_accessor :in_file, :in_files

  included do
    store_in collection: "ss_files"

    seqid :id
    field :model, type: String
    field :file_id, type: String
    field :state, type: String, default: "public"
    field :filename, type: String
    field :size, type: Integer
    field :content_type, type: String

    permit_params :state, :filename
    permit_params :in_file, :in_files, in_files: []

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
  end

  public
    def path
      "#{self.class.root}/ss_files/" + id.to_s.split(//).join("/") + "/_/#{id}"
    end

    def state_options
      [%w(公開 public)]
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

    def read
      Fs.exists?(path) ? Fs.binread(path) : nil
    end

    def save_files
      return false unless valid?

      in_files.each do |file|
        item = self.class.new(attributes)
        item.in_file = file
        next if item.save

        item.errors.full_messages.each {|m| errors.add :base, m }
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
      self.content_type = in_file.content_type
    end

    def save_file
      errors.add :in_file, :blank if new_record? && in_file.blank?
      return false if errors.present?
      return if in_file.blank?

      dir = ::File.dirname(path)
      Fs.mkdir_p(dir) unless Fs.exists?(dir)
      Fs.binwrite(path, in_file.read)
    end

    def remove_file
      Fs.rm_rf(path)
    end

    def validate_size
      if SS.config.env.max_filesize.present?
        if in_file.present?
          errors.add :base, :too_large_file if in_file.size > SS.config.env.max_filesize
        elsif in_files.present?
          in_files.each do |file|
            errors.add :base, :too_large_file if file.size > SS.config.env.max_filesize
          end
        end
      end
    end
end
