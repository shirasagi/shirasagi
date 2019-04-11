class Job::BindedJob < ::ActiveJob::ConfiguredJob
  def initialize(job_class, options = {}, bindings = {})
    super(job_class, options)
    @bindings = bindings.dup.stringify_keys
  end

  attr_reader :options
  attr_reader :bindings

  def perform_now(*args)
    if @bindings[:user_id].present?
      size = Job::Task.where(user_id: @bindings[:user_id]).where(state: 'stop').exists(at: true).count
      raise Job::SizeLimitExceededError, I18n.t('job.notice.size_limit_exceeded') if size >= Job::Service.config.size_limit_per_user
    end
    @job_class.new(*args).bind(@bindings).perform_now
  end

  def perform_later(*args)
    @job_class.new(*args).bind(@bindings).enqueue(@options)
  end

  def set(options)
    @options.merge!(options)
    self
  end

  def bind(bindings)
    @bindings.merge!(bindings.stringify_keys)
    self
  end
end
