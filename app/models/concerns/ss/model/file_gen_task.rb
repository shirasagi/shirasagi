#frozen_string_literal: true

module SS::Model::FileGenTask
  extend ActiveSupport::Concern
  include SS::Model::Task

  TIMER_MS = 3_000

  included do
    field :file_basename, type: String
    field :file_format, type: String
    field :params, type: Hash # arbitrary parameters for file generation job
    field :job_id, type: String # job_id is UUID

    validates :file_basename, presence: true
    validates :file_format, presence: true
  end

  def generated_file_path
    return if new_record?

    if log_sequence
      "#{base_dir}/#{log_sequence}_#{id}_#{file_basename}.#{file_format}"
    else
      "#{base_dir}/#{id}_#{file_basename}.#{file_format}"
    end
  end

  def public_filename
    "#{file_basename}_#{updated.to_i}.#{file_format}"
  end
end
