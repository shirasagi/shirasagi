module Gws::Addon::Workflow::CustomForm
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Reference::Workflow::Form

  included do
    field :custom_values, type: Hash

    before_validation :before_validation_custom_values
    validate :validate_custom_values
    before_save :before_save_custom_values
    after_save :after_save_custom_values
  end

  module ClassMethods
    def build_custom_values(form, hash)
      values = form.columns.map do |column|
        column_id = column.id.to_s
        value = Gws::Workflow::Column.to_mongo(column.input_type, hash[column_id])
        [ column_id, { 'input_type' => column.input_type, 'name' => column.name, 'value' => value } ]
      end
      Hash[values]
    end
  end

  def read_custom_value(column)
    return if custom_values.blank?

    column_id = column.respond_to?(:id) ? column.id.to_s : column.to_s
    val = custom_values[column_id]
    return if val.blank?

    Gws::Workflow::Column.from_mongo(val['input_type'], val['value'])
  end

  def write_custom_value(column, value)
    return if custom_values.blank?

    column_id = column.respond_to?(:id) ? column.id.to_s : column.to_s
    custom_values[column_id]['value'] = value
    nil
  end

  private

  def before_validation_custom_values
  end

  def validate_custom_values
    return if form.blank?
    validator = form.columns.to_validator(attributes: [:custom_values])
    validator.validate(self)
  end

  def before_save_custom_values
    validate_upload_files
    return if errors.present?
    save_upload_files
    # remove_upload_files
  end

  def validate_upload_files
    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      value = read_custom_value(column)
      if value.is_a?(ActionDispatch::Http::UploadedFile)
        file = read_relation_file(column)
        if file.invalid?
          errors[:base] += file.errors.full_messages
        end
      end
    end
  end

  def save_upload_files
    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      value = read_custom_value(column)
      if value.is_a?(ActionDispatch::Http::UploadedFile)
        file = read_relation_file(column)
        file.save

        write_custom_value(column, Gws::Workflow::Column.to_mongo(column.input_type, file.id))
      end
    end
  end

  def read_relation_file(column)
    value = read_custom_value(column)
    if value.is_a?(ActionDispatch::Http::UploadedFile)
      file = Gws::File.new
      file.in_file = value
      file.filename = value.original_filename
      file.site_id = site_id if respond_to?(:site_id)
      file.user_id = @cur_user.id if @cur_user
      file.resizing = column.resizing
      file
    else
      Gws::File.find(value) rescue nil
    end
  end

  def after_save_custom_values
  end
end
