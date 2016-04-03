class Job::BindedJob < ::ActiveJob::ConfiguredJob
  def initialize(job_class, options={}, bindings={})
    super(job_class, options)
    @bindings = bindings.dup.stringify_keys
  end

  def perform_now(*args)
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
