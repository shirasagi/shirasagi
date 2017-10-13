module Gws::Addon::CustomField
  extend ActiveSupport::Concern
  extend SS::Addon

  WELL_KNOWN_INPUT_TYPES = %w(text_field text_area email_field date_field radio_button select check_box upload_file).freeze

  included do
    class_variable_set(:@@_input_type_include_upload_file, nil)

    field :tooltips, type: SS::Extensions::Lines
    field :input_type, type: String
    field :select_options, type: SS::Extensions::Lines, default: ''
    field :required, type: String, default: 'required'
    field :max_length, type: Integer
    field :place_holder, type: String
    field :additional_attr, type: String, default: ''
    field :upload_file_count, type: Integer, default: 1
    field :max_upload_file_size, type: Integer
    field :resizing_width, type: Integer
    field :resizing_height, type: Integer

    attr_accessor :in_max_upload_file_size_mb

    permit_params :input_type, :tooltips, :required
    permit_params :max_length, :place_holder, :additional_attr, :select_options
    permit_params :upload_file_count, :in_max_upload_file_size_mb, :resizing_width, :resizing_height

    after_initialize do
      if self.max_upload_file_size
        self.in_max_upload_file_size_mb = self.max_upload_file_size / (1_024 * 1_024)
      end
    end

    before_validation do
      if self.in_max_upload_file_size_mb.present?
        self.max_upload_file_size = Integer(self.in_max_upload_file_size_mb) * 1_024 * 1_024
      else
        self.max_upload_file_size = nil
      end
    end

    validates :input_type, presence: true, inclusion: { in: WELL_KNOWN_INPUT_TYPES, allow_blank: true }
    validates :required, inclusion: { in: %w(required optional), allow_blank: true }
    validates :max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :max_upload_file_size, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :resizing_width, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validates :resizing_height, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validate :validate_select_options
  end

  module ClassMethods
    def to_permitted_fields
      params = []

      criteria.each do |item|
        if item.input_type == 'check_box'
          params << { item.id.to_s => [] }
        elsif item.input_type == 'upload_file'
          params << { item.id.to_s => [ 'value', 'file' => [], 'rm' => [] ] }
        else
          params << item.id.to_s
        end
      end

      params
    end

    def build_custom_values(hash)
      values = []
      all.each do |item|
        item_id = item.id.to_s
        value = to_mongo(item.input_type, hash[item_id])
        values << [ item_id, item.serialize_value(value) ]
      end
      Hash[values]
    end

    def to_validator(options)
      criteria = self.criteria.dup
      ActiveModel::BlockValidator.new(options.dup) do |record, attribute, value|
        criteria.each do |item|
          item.validate_value(record, attribute, value)
        end
      end
    end

    def input_type_include_upload_file?
      class_variable_get(:@@_input_type_include_upload_file)
    end

    def to_mongo(input_type, value)
      return value unless value

      case input_type
      when 'text_field', 'text_area', 'email_field', 'date_field', 'radio_button', 'select'
        String.mongoize(value)
      when 'check_box'
        value.map { |v| String.mongoize(v) }
      when 'upload_file'
        case value
        when Array
          value.map { |v| to_mongo_upload_file(input_type, v) }
        else
          to_mongo_upload_file(input_type, value)
        end
      else
        value
      end
    end

    def from_mongo(input_type, value)
      return value unless value

      case input_type
      when 'text_field', 'text_area', 'email_field', 'date_field', 'radio_button', 'select'
        String.demongoize(value)
      when 'check_box'
        value.map { |v| String.demongoize(v) }
      when 'upload_file'
        case value
        when Array
          value.map { |v| from_mongo_upload_file(input_type, v) }
        else
          from_mongo_upload_file(input_type, value)
        end
      else
        value
      end
    end

    private

    def input_type_include_upload_file
      class_variable_set(:@@_input_type_include_upload_file, true)
    end

    def to_mongo_upload_file(input_type, value)
      case value
      when ActionDispatch::Http::UploadedFile, Hash
        value
      else
        Integer.mongoize(value)
      end
    end

    def from_mongo_upload_file(input_type, value)
      case value
      when ActionDispatch::Http::UploadedFile, Hash
        value
      else
        Integer.demongoize(value)
      end
    end
  end

  def input_type_options
    ret = %w(text_field text_area email_field date_field radio_button select check_box).map do |v|
      [ I18n.t("gws.options.input_type.#{v}"), v ]
    end

    if self.class.input_type_include_upload_file?
      ret << [ I18n.t('inquiry.options.input_type.upload_file'), 'upload_file' ]
    end

    ret
  end

  def required_options
    [
      [I18n.t('inquiry.options.required.required'), 'required'],
      [I18n.t('inquiry.options.required.optional'), 'optional'],
    ]
  end

  def required?
    required == 'required'
  end

  def additional_attr_to_h
    additional_attr.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  def html_options
    options = additional_attr_to_h
    options['maxlength'] = max_length if max_length.present?
    options['placeholder'] = place_holder if place_holder.present?
    if input_type == 'date_field'
      options['class'] = [ options['class'] ].flatten.compact
      options['class'] << 'date'
      options['class'] << 'js-date'
    end
    options
  end

  def serialize_value(value)
    ret = { 'input_type' => self.input_type, 'order' => self.order, 'name' => self.name }
    if value.is_a?(Hash)
      ret.merge!(value)
    else
      ret['value'] = value
    end
    ret
  end

  def validate_value(record, attribute, value)
    hash = value[id.to_s]
    input_type = hash['input_type']

    return unless WELL_KNOWN_INPUT_TYPES.include?(input_type)

    send("validate_#{input_type}_value", record, hash)
  end

  def resizing
    if resizing_width.present? && resizing_height.present?
      [ resizing_width, resizing_height ]
    end
  end

  private

  def validate_select_options
    if input_type =~ /(select|radio_button|check_box)/
      errors.add :select_options, :blank if select_options.blank?
    end
  end

  def validate_text_field_value(record, hash)
    value = hash['value']

    if required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    if max_length.present? && max_length > 0
      if value.length > max_length
        record.errors.add(:base, name + I18n.t('errors.messages.less_than_or_equal_to', count: max_length))
      end
    end
  end
  alias validate_text_area_value validate_text_field_value
  alias validate_email_field_value validate_text_field_value
  alias validate_date_field_value validate_text_field_value

  def validate_radio_button_value(record, hash)
    value = hash['value']

    if required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    unless select_options.include?(value)
      record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
    end
  end
  alias validate_select_value validate_radio_button_value

  def validate_check_box_value(record, hash)
    values = hash['value']
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

  def validate_upload_file_value(record, hash)
    files = hash['file']
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
