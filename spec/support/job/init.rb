module SS
  module JobSupport
    module_function

    # ShirasagiAdapter で実行するようにジョブを実行する。
    # つまり、より本番環境に近い形でジョブを実行する。
    # 単に perform_now でジョブを実行するとジョブキュー制限が働かないが、
    # 本ヘルパーメソッドでジョブを実行するとジョブキュー制限も機能するようになる。
    def ss_perform_now(job, *args)
      if job.is_a?(::ActiveJob::ConfiguredJob)
        job_class = job.instance_variable_get(:@job_class)
        bindings = job.bindings
      elsif job.ancestors.include?(ActiveJob::Base)
        job_class = job
        bindings = nil
      end
      job = job_class.new(*args)
      job = job.bind(bindings) if bindings && job.respond_to?(:bind)

      task = Job::Task.new(
        name: job.job_id,
        class_name: job.class.name,
        app_type: job.class.try(:ss_app_type),
        pool: job.queue_name,
        args: job.arguments,
        active_job: job.serialize)
      if site_id = job.try(:site_id)
        if job.class.ss_app_type.to_sym == :gws
          task.group_id = site_id
        else
          task.site_id = site_id
        end
      end
      if user_id = job.try(:user_id)
        task.user_id = user_id
      end
      task.save!

      task.execute
    ensure
      task.destroy rescue nil
    end
  end
end

RSpec.configuration.include(SS::JobSupport)
