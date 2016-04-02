module ActiveJob
  module QueueAdapters
    class ShirasagiAdapter
      class << self
        def enqueue(job) #:nodoc:
          Wrapper.call_async(job.serialize) do |ss_job|
            copy_job_meta(ss_job, job)
          end
          run_rake_if_needed
        end

        def enqueue_at(job, timestamp) #:nodoc:
          Wrapper.call_at(timestamp, job.serialize) do |ss_job|
            copy_job_meta(ss_job, job)
          end
          run_rake_if_needed
        end

        private
          def copy_job_meta(ss_job, active_job)
            ss_job.pool = active_job.queue_name

            if site_id = active_job.try(:site_id)
              ss_job.site_id = site_id
            end

            if user_id = active_job.try(:user_id)
              ss_job.user_id = user_id
            end
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

      class Wrapper
        include Job::Worker

        def call(job_data)
          ::ActiveJob::Base.execute(job_data)
        end
      end
    end
  end
end
