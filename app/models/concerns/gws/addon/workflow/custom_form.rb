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
    after_destroy :after_destroy_custom_values
  end

  module ClassMethods
    def build_custom_values(form, hash)
      values = []
      form.columns.each do |column|
        column_id = column.id.to_s
        value = Gws::Workflow::Column.to_mongo(column.input_type, hash[column_id])
        if value.is_a?(Hash)
          values << [ column_id, { 'input_type' => column.input_type, 'name' => column.name }.merge(value) ]
        else
          values << [ column_id, { 'input_type' => column.input_type, 'name' => column.name, 'value' => value } ]
        end
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

  def remove_custom_value(column)
    return if custom_values.blank?

    column_id = column.respond_to?(:id) ? column.id.to_s : column.to_s
    self.custom_values.delete(column_id)
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
    remove_upload_files
    save_upload_files
  end

  def validate_upload_files
    return if custom_values.blank?

    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      hash = custom_values[column.id.to_s]
      next if hash.blank?

      uploaded_file = hash['file']
      next if uploaded_file.blank?

      file = build_file(column, uploaded_file)
      next if file.valid?

      errors[:base] += file.errors.full_messages
    end
  end

  def remove_upload_files
    return if custom_values.blank?

    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      hash = custom_values[column.id.to_s]
      next if hash.blank?

      do_destroy = false

      rm_flag = hash['rm']
      do_destroy = true if rm_flag == '1'

      uploaded_file = hash['file']
      do_destroy = true if uploaded_file.present?

      next unless do_destroy

      file_id = hash['value']
      if file_id.blank?
        hash.delete('rm')
        hash.delete('value')
        custom_values[column.id.to_s] = hash
        next
      end

      file = Gws::File.site(site).find(file_id) rescue nil
      if file.blank?
        hash.delete('rm')
        hash.delete('value')
        custom_values[column.id.to_s] = hash
        next
      end

      file.destroy
      hash.delete('rm')
      hash.delete('value')
      custom_values[column.id.to_s] = hash
    end
  end

  def save_upload_files
    return if custom_values.blank?

    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      hash = custom_values[column.id.to_s]
      next if hash.blank?

      uploaded_file = hash['file']
      next if uploaded_file.blank?

      file = build_file(column, uploaded_file)
      next if file.invalid?

      file.save!

      hash['value'] = file.id
      hash.delete('file')

      custom_values[column.id.to_s] = hash
    end
  end

  def build_file(column, uploaded_file)
    file = Gws::File.new
    file.in_file = uploaded_file
    file.filename = uploaded_file.original_filename
    file.site_id = site_id if respond_to?(:site_id)
    file.user_id = @cur_user.id if @cur_user
    file.resizing = column.resizing
    file
  end

  def after_save_custom_values
  end

  def after_destroy_custom_values
    return if custom_values.blank?

    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      hash = custom_values[column.id.to_s]
      next if hash.blank?

      file_id = hash['value']
      next if file_id.blank?

      file = Gws::File.site(site).find(file_id) rescue nil
      next if file.blank?

      file.destroy
    end
  end
end
