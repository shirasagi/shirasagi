class Cms::MicheckerJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::MicheckerTask
  self.task_name = Cms::MicheckerTask::TASK_NAME

  def perform(*args, **options)
    @url = args.first

    @task.michecker_last_job_id = job_id
    @task.save

    @task.log "miChecker による検証を開始します。"

    # result = run_html_checker_and_wait
    result = 2

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

    filepath = @task.html_checker_report_filepath
    dir_path = ::File.dirname(filepath)
    ::FileUtils.mkdir_p(dir_path) unless ::Dir.exist?(dir_path)

    basename = ::File.basename(filepath)
    tmp_filepath = "#{dir_path}/.#{basename}.$$"

    commands = commands.dup
    commands << "htmlchecker"
    commands << "--output-report"
    commands << tmp_filepath
    commands << @url

    pid = spawn(*commands, { chdir: SS.config.cms.michecker["working_directory"] })
    _, status = Process.waitpid2(pid)
    if status.success?
      ::FileUtils.copy_file(tmp_filepath, filepath)
    end

    status.exitstatus
  ensure
    if tmp_filepath.present?
      ::FileUtils.rm_f(tmp_filepath) rescue nil
    end
  end
end
