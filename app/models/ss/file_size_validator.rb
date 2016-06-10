class SS::FileSizeValidator < ActiveModel::Validator
  include ActiveSupport::NumberHelper

  def validate(record)
    if record.in_file.present?
      validate_limit(record, record.in_file)
    elsif record.in_files.present?
      record.in_files.each { |file| validate_limit(record, file) }
    end
  end

  private
    def validate_limit(record, file)
      filename = file.original_filename
      ext = filename.sub(/.*\./, "").downcase
      limit_size = SS::MaxFileSize.find_size(ext)

      return true if file.size <= limit_size

      record.errors.add :base, :too_large_file, filename: filename,
        size: number_to_human_size(file.size),
        limit: number_to_human_size(limit_size)
      false
    end
end
