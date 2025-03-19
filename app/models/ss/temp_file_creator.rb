#frozen_string_literal: true

# SS::File#name や SS::File#filename は自動で正規化して良い感じにしてしまう。
# そうではなくて、違反がある場合はユーザーにフィードバックしたい
class SS::TempFileCreator
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attr_accessor :ss_mode, :cur_site, :cur_user, :cur_node
  attr_reader :work_item

  attribute :name, :string
  attribute :filename, :string
  attribute :resizing, :string
  attribute :quality, :string
  attribute :image_resizes_disabled, :string
  attribute :in_file
  attribute :only_image, :boolean

  before_validation :normalize_name
  before_validation :normalize_filename

  validates :name, presence: true
  validates :filename, presence: true
  validate :validate_name
  validate :validate_filename
  validate :validate_size
  validate :validate_image

  def model
    @model ||= begin
      if ss_mode == :cms
        Cms::TempFile
      else
        SS::TempFile
      end
    end
  end

  def new_item
    if ss_mode == :cms
      model.new(cur_site: cur_site, cur_user: cur_user, cur_node: cur_node)
    else
      model.new(cur_user: cur_user)
    end
  end

  def save
    return false if invalid?

    item = new_item
    item.name = name
    item.filename = filename
    item.resizing = resizing
    item.quality = quality
    item.image_resizes_disabled = image_resizes_disabled
    item.in_file = in_file

    result = item.save
    if result
      @work_item = item
    else
      SS::Model.copy_errors(item, self)
    end
    result
  end

  private

  def normalize_name
    return if in_file.blank? || name.blank?

    # 拡張子が存在しない、または、マッチしない場合、拡張子を追加する
    original_ext = File.extname(in_file.original_filename)
    ext = File.extname(name)
    if original_ext != ext
      new_name = "#{name}#{original_ext}"
      new_name = new_name.gsub("..", ".") if new_name.include?("..")
      self.name = new_name
    end
  end

  def normalize_filename
    return if in_file.blank?

    if filename.blank?
      return if name.blank?
      self.filename = SS::FilenameUtils.convert(name, id: next_sequence)
    end

    # 拡張子が存在しない、または、マッチしない場合、拡張子を追加する
    original_ext = File.extname(in_file.original_filename)
    ext = File.extname(filename)
    if original_ext != ext
      new_filename = "#{filename}#{original_ext}"
      new_filename = new_filename.gsub("..", ".") if new_filename.include?("..")
      self.filename = new_filename
    end
  end

  def validate_name
    return if name.blank?

    if multibyte_filename_disabled?
      if name !~ /^\/?([\w\-]+\/)*[\w\-]+\.[\w\-.]+$/
        message = I18n.t("errors.messages.invalid_filename")
        message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
        errors.add :base, message
      end
    else
      safe_name = SS::FilenameUtils.convert_to_url_safe_japanese(name)
      if name != safe_name
        message = I18n.t("errors.messages.invalid")
        message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
        errors.add :base, message
      end
    end
  end

  def multibyte_filename_disabled?
    return false if cur_site.blank? || !cur_site.respond_to?(:multibyte_filename_disabled?)
    cur_site.multibyte_filename_disabled?
  end

  def validate_filename
    return if filename.blank?

    if filename !~ /^\/?([\w\-]+\/)*[\w\-]+\.[\w\-.]+$/
      message = I18n.t("errors.messages.invalid_filename")
      message = I18n.t("errors.format", attribute: SS::File.t(:filename), message: message)
      errors.add :base, message
    end
  end

  def validate_size
    return if in_file.blank? || filename.blank?

    ext = filename.sub(/.*\./, "").downcase
    limit_size = SS::MaxFileSize.find_size(ext)
    return if in_file.size <= limit_size

    message = I18n.t("errors.messages.too_large_file", filename: filename,
      size: in_file.size.to_fs(:human_size),
      limit: limit_size.to_fs(:human_size)
    )
    errors.add :base, message
  end

  def validate_image
    return unless only_image

    unless SS::ImageConverter.image?(in_file)
      message = I18n.t("errors.messages.image")
      message = I18n.t("errors.format", attribute: SS::File.t(:in_files), message: message)

      errors.add :base, message
    end
  end

  def next_sequence
    sequence = SS::Sequence.where(id: "ss_files_id").first
    current_sequence = sequence.try(:value) || 0
    current_sequence + 1
  end
end
