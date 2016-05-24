class Job::Service::Config
  extend Forwardable

  # default pool max size
  # -1 means unlimited
  DEFAULT_POOL_MAX_SIZE = -1

  def initialize(section = 'default')
    @config = OpenStruct.new(::SS.config.job[section])
  end

  def_delegators(:@config, :name, :name=)
  def_delegators(:@config, :mode, :mode=)
  def_delegators(:@config, :log_level, :log_level=)

  def polling
    ret = @config.polling
    if ret.is_a?(Hash)
      ret = OpenStruct.new(ret)
      @config.polling = ret
    end
    ret
  end

  class << self
    def max_size_of(pool_name)
      pool_config = SS.config.job.pool[pool_name]
      return DEFAULT_POOL_MAX_SIZE unless pool_config

      pool_config.fetch('max_size', DEFAULT_POOL_MAX_SIZE)
    end
  end
end
