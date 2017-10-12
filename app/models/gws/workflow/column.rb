class Gws::Workflow::Column
  include SS::Document
  include Gws::Addon::CustomField
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Workflow::Form

  input_type_include_upload_file

  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in(params[:keyword], :name)
      end

      criteria
    end
  end

  def validate_value(record, attribute, hash)
    # value = record.read_custom_value(self)
    item = hash[id.to_s]
    input_type = item['input_type']

    return unless WELL_KNOWN_INPUT_TYPES.include?(input_type)

    send("validate_#{input_type}_value", item)
  end

  private

  def validate_text_field_value(item)
    value = item['value']

    if required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end
  end
  alias validate_text_area_value validate_text_field_value
  alias validate_email_field_value validate_text_field_value
  alias validate_date_field_value validate_text_field_value

  def validate_radio_button_value(item)
    value = item['value']

    if required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    unless select_options.include?(value)
      record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
    end
  end
  alias validate_select_value validate_radio_button_value

  def validate_check_box_value(item)
    values = item['value']
    values = [ values ].flatten.compact.select(&:present?)

    if required? && values.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if values.blank?

    diff = values - select_options
    if diff.present?
      record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: diff.join(', ')))
    end
  end

  def validate_upload_file_value(item)
    files = item['file']
    files = [ files ].flatten.compact.select(&:present?)
    if required? && files.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if files.blank?

    if files.count > upload_file_count
      message = I18n.t(
        'errors.messages.file_count',
        size: ApplicationController.helpers.number_to_human(files.count),
        limit: ApplicationController.helpers.number_to_human(upload_file_count)
      )
      record.errors.add(:base, "#{name}#{message}")
    end

    files.each do |file|
      next unless file.is_a?(ActionDispatch::Http::UploadedFile)

      if file.size > max_upload_file_size
        message = I18n.t(
          'errors.messages.too_large_file',
          filename: file.original_filename,
          size: ApplicationController.helpers.number_to_human_size(file.size),
          limit: ApplicationController.helpers.number_to_human_size(max_upload_file_size)
        )
        record.errors.add(:base, "#{name}#{message}")
      end
    end
  end
end
