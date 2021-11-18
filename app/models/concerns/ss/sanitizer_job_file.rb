module SS::SanitizerJobFile
  extend ActiveSupport::Concern

  included do
    field :job_name, type: String
    field :job_wait, type: Integer
  end

  def task
    SS::Task.find_by(name: job_name) rescue nil
  end

  def sanitizer_job(job)
    return job unless SS::UploadPolicy.upload_policy == 'sanitizer'
    return job unless try(:file_id) || try(:file_ids)
    job.delay_wait
  end

  class << self
    def job_models
      {
        'cms/import_file' => Cms::ImportJobFile
      }
    end

    def restore_wait_job(file)
      job_model = job_models[file.model]
      return false unless job_model

      item = job_model.site(file.site).where(file_ids: file.id).first
      return false unless item

      task = item.task
      return false unless task

      wait = item.job_wait || Time.zone.now.to_i
      item.set(job_wait: nil)
      task.set(at: wait)

      ActiveJob::QueueAdapters::ShirasagiAdapter.run_rake_if_needed
      return true
    end
  end
end
