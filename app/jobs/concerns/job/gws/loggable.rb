module Job::Gws::Loggable
  extend ActiveSupport::Concern
  include Job::SS::Loggable

  private
    # overwrite method
    def create_job_log
      Gws::Job::Log.create_from_active_job(self)
    end
end
