class Job::BindedJob < ::ActiveJob::ConfiguredJob
  def initialize(job_class, options = {}, bindings = {})
    super(job_class, **options)
    @bindings = bindings.dup.stringify_keys
  end

  attr_reader :bindings, :options, :job_wait

  def perform_now(*args)
    # 一人当たりのジョブキュー制限は、多数のジョブが追加されてシステムの処理が追い付かなくなるのを防ぐのが目的。
    # perform_now の場合、ジョブをキューに入れることはなく即座に実行されるので、この制限を適用するのは適切ではない。
    # また、組織変更内でコンテンツインポートを実行しているが、この制限があると組織変更内でコンテンツインポートが実行できない。
    # user_id_or_user = @bindings[:user_id].presence || @bindings["user_id"]
    # user_id_or_user = user_id_or_user.id if user_id_or_user.respond_to?(:id)
    # ApplicationJob.check_size_limit_per_user!(user_id_or_user)
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
