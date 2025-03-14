#frozen_string_literal: true

class SS::TempFilePreview
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attr_accessor :cur_site, :cur_user

  attribute :name, :string
  attribute :filename, :string
  attribute :size, :integer
  attribute :content_type, :string
  attribute :is_image, :boolean

  before_validation :normalize_name
  before_validation :normalize_filename
  before_validation :set_is_image

  validates :name, presence: true
  validates :filename, presence: true
  validates :size, presence: true
  validate :validate_filename
  validate :validate_size

  def to_h
    { name: name, filename: filename, size: size, content_type: content_type,
      is_image: is_image, errors: errors.full_messages }
  end

  private

  def normalize_name
    return if name.blank?
    self.name = SS::FilenameUtils.convert_to_url_safe_japanese(name)
  end

  def normalize_filename
    return if filename.present?
    return if name.blank?

    filename = SS::FilenameUtils.normalize(name)
    filename = SS::FilenameUtils.convert(filename, id: next_sequence)
    self.filename = filename
  end

  def set_is_image
    if filename.blank?
      self.is_image = false
      return
    end

    content_type = SS::MimeType.find(filename)
    self.is_image = SS::ImageConverter.image_mime_type?(content_type)
  end

  def multibyte_filename_disabled?
    return false if cur_site.blank? || !cur_site.respond_to?(:multibyte_filename_disabled?)
    cur_site.multibyte_filename_disabled?
  end

  def validate_filename
    return if filename.blank?

    if multibyte_filename_disabled? && filename !~ /^\/?([\w\-]+\/)*[\w\-]+\.[\w\-.]+$/
      message = I18n.t("errors.messages.invalid_filename")
      message = I18n.t("errors.format", attribute: SS::File.t(:filename), message: message)
      errors.add :base, message
    end
  end

  def validate_size
    return if filename.blank?

    ext = filename.sub(/.*\./, "").downcase
    limit_size = SS::MaxFileSize.find_size(ext)
    return if size <= limit_size

    message = I18n.t("errors.messages.too_large_file", filename: filename,
      size: size.to_fs(:human_size),
      limit: limit_size.to_fs(:human_size)
    )
    errors.add :base, message
  end

  def next_sequence
    sequence = SS::Sequence.where(id: "ss_files_id").first
    current_sequence = sequence.try(:value) || 0
    current_sequence + 1
  end
end
