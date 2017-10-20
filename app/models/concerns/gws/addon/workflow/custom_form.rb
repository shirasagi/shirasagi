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
    validator = form.to_validator(attributes: [:custom_values])
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

      uploaded_files = hash['file']
      next if uploaded_files.blank?

      uploaded_files.each do |uploaded_file|
        file = build_file(column, uploaded_file)
        next if file.valid?
        errors[:base] += file.errors.full_messages
      end
    end
  end

  def remove_upload_files
    return if custom_values.blank?

    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      hash = custom_values[column.id.to_s]
      next if hash.blank?

      rm_file_ids = hash['rm']
      next if rm_file_ids.blank?

      rm_file_ids.select(&:present?).each do |rm_file_id|
        rm_file_id = Integer(rm_file_id) rescue nil
        next unless rm_file_id

        file = Gws::File.site(site).find(rm_file_id) rescue nil
        file.destroy if file
        hash['value'].delete(rm_file_id) rescue nil
      end

      hash.delete('rm')
      hash.delete('value') if hash['value'].blank?
      custom_values[column.id.to_s] = hash
    end
  end

  def save_upload_files
    return if custom_values.blank?

    self.cur_form.columns.where(input_type: 'upload_file').each do |column|
      hash = custom_values[column.id.to_s]
      next if hash.blank?

      uploaded_files = hash['file']
      next if uploaded_files.blank?

      uploaded_files.each do |uploaded_file|
        file = build_file(column, uploaded_file)
        next if file.invalid?

        file.save!

        hash['value'] ||= []
        hash['value'] << file.id
      end

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

      file_ids = hash['value']
      next if file_ids.blank?

      file_ids.each do |file_id|
        file = Gws::File.site(site).find(file_id) rescue nil
        next if file.blank?

        file.destroy
      end
    end
  end
end
