class Gws::Job::Log
  include SS::Model::JobLog
  # include Gws::Reference::Site
  include Gws::SitePermission

  belongs_to :group, class_name: "Gws::Group"
  validates :group_id, presence: true
  scope :site, ->(site) { where( group_id: site.id ) }

  alias site group
  alias site_id group_id

  class << self
    def create_from_active_job(job)
      self.create(
        group_id: job.try(:site_id),
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
