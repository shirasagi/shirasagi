class Gws::Column::Value::FileUpload < Gws::Column::Value::Base
  embeds_ids :files, class_name: 'SS::File'

  before_save :before_save_files
  after_destroy :delete_files

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && files.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if files.blank?

    if files.count > column.upload_file_count
      message = I18n.t(
        'errors.messages.file_count',
        size: ApplicationController.helpers.number_to_human(files.count),
        limit: ApplicationController.helpers.number_to_human(column.upload_file_count)
      )
      record.errors.add(:base, "#{name}#{message}")
    end

    # files.each do |file|
    #   if file.size > column.max_upload_file_size
    #     message = I18n.t(
    #       'errors.messages.too_large_file',
    #       filename: file.humanize_name,
    #       size: ApplicationController.helpers.number_to_human_size(file.size),
    #       limit: ApplicationController.helpers.number_to_human_size(column.max_upload_file_size)
    #     )
    #     record.errors.add(:base, "#{name}#{message}")
    #   end
    # end
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    self.file_ids = new_value.file_ids
    self.text_index = new_value.value
  end

  def value
    files.pluck(:name).join(', ')
  end

  private

  def before_save_files
    if file_ids_was.present?
      removed_file_ids = normalized_file_ids(file_ids_was) - normalized_file_ids(file_ids)
      removed_file_ids.each do |file_id|
        removed_file = SS::File.find(file_id) rescue nil
        removed_file.destroy if removed_file
      end
    end

    files.each do |file|
      next if file.blank?
      next if file.model == 'gws/column_value'

      file.model = 'gws/column_value'
      file.save!
    end
  end

  def delete_files
    return if files.blank?

    self.files.destroy_all
    self.file_ids = nil
  end

  def normalized_file_ids(ids)
    return [] if ids.blank?
    ids.select(&:present?).map(&:to_i)
  end
end
