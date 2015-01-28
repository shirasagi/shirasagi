require 'English'
require 'json'
require 'time'

module Job::Worker
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    @job_options_hash

    def call_async(*args, &block)
      enqueue_job(
        class_name: self.to_s,
        args: args,
        &block)
    end

    def call_in(interval, *args, &block)
      interval = interval.to_f
      at = interval < 1_000_000_000 ? Time.now.to_f + interval : interval
      enqueue_job(
        class_name: self.to_s,
        args: args,
        at: at,
        &block)
    end

    alias_method :call_at, :call_in

    def job_options
      @job_options_hash ||= {}
      @job_options_hash
    end

    def job_options=(hash)
      @job_options_hash = hash.merge(self.job_options).stringify_keys
    end

    def enqueue_job(entity, &block)
      pool = get_pool(entity)
      entity['pool'] = pool

      check_size_limit(pool)

      task = Job::Model.enqueue(entity, &block)
      Rails.logger.debug("Submitted Job: id=#{task.id}, name=#{task.name}, class_name=#{task.class_name}, args=#{task.args}")
      task
    end

    private
      def get_pool(entity)
        pool = entity['pool'] rescue nil
        pool.present? ? pool : default_pool
      end

      def default_pool
        self.job_options.key?('pool') ?  self.job_options['pool'] : 'default'
      end

      def check_size_limit(pool)
        pool_config = PoolConfig.new(SS.config.job.pool[pool])

        if pool_config.max_size?
          size = Job::Model.where(pool: pool).count
          raise "size limit exceeded" if size >= pool_config.max_size
        end
      end
  end

  class PoolConfig
    public
      def initialize(config)
        @config = config || {}
      end

      def max_size?
        @config.key?('max_size')
      end

      def max_size
        @config['max_size'].to_i
      end
  end
end
