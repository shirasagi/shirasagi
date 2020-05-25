class Cms::MicheckerJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::MicheckerTask
  self.task_name = Cms::MicheckerTask::TASK_NAME

  def perform(*args, **options)
    @url = args.first

    @task.michecker_last_job_id = job_id
    @task.save

    @task.log "miChecker による検証を開始します。"

    result = run_html_checker_and_wait
    if result == 0
      @task.log "miChecker による検証が完了しました。"
    else
      @task.log "miChecker による検証が失敗しました。"
    end

    @task.michecker_last_result = result
    @task.michecker_executed_at = Time.zone.now
    @task.save
  end

  private

  def task_cond
    cond = super
    cond[:user_id] = user_id
    cond
  end

  def run_html_checker_and_wait
    commands = Array(SS.config.cms.michecker["command"]).compact
    return if commands.blank?

    commands = commands.dup
    commands << "--no-interactive"
    commands << "--html-checker-output-report"
    commands << @task.html_checker_report_filepath
    commands << "--lowvision-output-report"
    commands << @task.low_vision_report_filepath
    commands << "--lowvision-output-image"
    commands << @task.low_vision_source_filepath
    commands << "--lowvision-source-image"
    commands << @task.low_vision_result_filepath
    commands << @url

    pid = spawn(*commands)
    _, status = Process.waitpid2(pid)

    status.exitstatus
  end
end
