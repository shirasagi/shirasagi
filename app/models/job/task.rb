class Job::Task
  extend SS::Translation
  include SS::Document
  include SS::Model::Task
  include SS::Reference::User
  #include SS::Reference::Site

  field :pool, type: String
  field :class_name, type: String
  field :args, type: Array
  field :priority, type: Integer, default: -> { Time.zone.now.to_i }
  field :at, type: Integer, default: -> { Time.zone.now.to_i }
  field :active_job, type: Hash

  belongs_to :site, class_name: "SS::Site"

  before_validation :set_name

  scope :site, ->(site) { where(site_id: (site.nil? ? nil : site.id)) }

  class << self
    def enqueue(entity)
      model = Job::Task.new(entity)
      yield model if block_given?
      model.save!
      model
    end

    def dequeue(name)
      criteria = Job::Task.where(pool: name, started: nil)
      criteria = criteria.lte(at: Time.zone.now)
      criteria = criteria.asc(:priority)
      criteria.find_one_and_update({ '$set' => { started: Time.zone.now }}, return_document: :after)
    end
  end

  def execute
    job = self.class_name.constantize.new
    if job.is_a?(ActiveJob::Base)
      execute_active_job
    else
      execute_shirasagi(job)
    end
  end

  private
    def set_name
      self.name = 'job:model' if self.name.blank?
    end

    def execute_active_job
      ::ActiveJob::Base.execute(active_job)
    end

    def execute_shirasagi(job)
      with_job_log do
        job.call(*args)
      end
    end

    def with_job_log
      job_log = Job::Log.add(self)
      Job::TaskLogger.attach(job_log)
      ret = nil
      begin
        Rails.logger.info("Started Job #{id}")
        job_log.state = Job::Log::STATE_RUNNING
        job_log.started = Time.zone.now
        job_log.save

        time = Benchmark.realtime do
          ret = yield
        end
      rescue Exception => e
        job_log.state = Job::Log::STATE_FAILED
        job_log.closed = Time.zone.now
        Rails.logger.fatal("Failed Job #{id}: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        raise if system_error?(e)
      else
        job_log.state = Job::Log::STATE_COMPLETED
        job_log.closed = Time.zone.now
        Rails.logger.info("Completed Job #{id} in #{time * 1000} ms")
      ensure
        Job::TaskLogger.detach(job_log)
        job_log.save
      end
      ret
    end

    def system_error?(e)
      e.kind_of?(NoMemoryError) || e.kind_of?(SignalException) || e.kind_of?(SystemExit)
    end
end
