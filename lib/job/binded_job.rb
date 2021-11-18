class Job::BindedJob < ::ActiveJob::ConfiguredJob
  def initialize(job_class, options = {}, bindings = {})
    super(job_class, **options)
    @bindings = bindings.dup.stringify_keys
  end

  attr_reader :bindings, :options, :job_wait

  def perform_now(*args)
    user_id_or_user = @bindings[:user_id].presence || @bindings["user_id"]
    user_id_or_user = user_id_or_user.id if user_id_or_user.respond_to?(:id)
    ApplicationJob.check_size_limit_per_user!(user_id_or_user)
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

  def delay_wait
    if @options[:wait_until]
      @job_wait = @options.delete(:wait_until).to_i
    elsif @options[:wait]
      @job_wait = @options.delete(:wait).since.to_i
    else
      @job_wait = Time.zone.now.to_i
    end

    set(wait: 1.year)
  end
end
