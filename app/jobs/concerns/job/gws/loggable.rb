module Job::Gws::Loggable
  extend ActiveSupport::Concern
  include Job::SS::Loggable

  private

  # overwrite method
  def create_job_log!
    job_log = Gws::Job::Log.create_from_active_job!(self)

    # （主としてRSpec対策）ゴミが残っている可能性を考慮して、念のためにクリアする
    file_path = job_log.file_path
    dirname = ::File.dirname(file_path)
    ::FileUtils.rm_rf(dirname)

    job_log
  end
end
