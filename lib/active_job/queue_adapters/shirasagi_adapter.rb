module ActiveJob
  module QueueAdapters
    class ShirasagiAdapter
      class << self
        def enqueue(job) #:nodoc:
          enqueue_at(job, nil)
        end

        def enqueue_at(job, timestamp) #:nodoc:
          check_size_limit(job.queue_name)

          create_task(job, timestamp)

          run_rake_if_needed
        end

        private
          def check_size_limit(pool)
            pool_config = SS.config.job.pool[pool] || {}

            max_size = pool_config.fetch('max_size', -1)
            return if max_size <= 0

            size = Job::Task.where(pool: pool).count
            raise Job::SizeLimitExceededError, "size limit exceeded" if size >= max_size
          end

          def create_task(job, timestamp)
            task = Job::Task.new(
              name: job.job_id,
              class_name: job.class.name,
              pool: job.queue_name,
              args: job.arguments,
              active_job: job.serialize)
            task.at = timestamp.to_i if timestamp
            if site_id = job.try(:site_id)
              task.site_id = site_id
            end
            if user_id = job.try(:user_id)
              task.user_id = user_id
            end
            task.save!
          end

          def run_rake_if_needed
            # check for on demand run is enabled
            return unless SS.config.job.enable_on_demand_run

            # check for whether service is started or not
            name = SS.config.job['default']['model']
            service = Job::Service.where(name: name).order_by(updated: -1).first
            return if service && service.current_count > 0

            # start job execution service
            ::SS::RakeRunner.run_async "job:run", "RAILS_ENV=#{Rails.env}"
          end
      end
    end
  end
end
