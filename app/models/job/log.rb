class Job::Log
  include SS::Model::JobLog

  belongs_to :site, class_name: "SS::Site"

  scope :site, ->(site) { where(site_id: (site.nil? ? nil : site.id)) }

  class << self
    def add(task)
      # copy all members
      log = Job::Log.new(
        site_id: task.site_id,
        user_id: task.user_id,
        job_id: task.id,
        state: task.state,
        started: task.started,
        closed: task.closed,
        logs: task.logs,
        pool: task.pool,
        class_name: task.class_name,
        args: task.args,
        priority: task.priority,
        at: task.at)
      log.save!
      log
    end

    def create_from_active_job(job)
      self.create(
        site_id: job.try(:site_id),
        user_id: job.try(:user_id),
        job_id: job.job_id,
        state: 'stop',
        pool: job.queue_name,
        class_name: job.class.name,
        args: job.arguments
      )
    end
  end
end
