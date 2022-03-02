class Cms::MicheckerJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Michecker::Result
  self.task_name = Cms::Michecker::Result::TASK_NAME

  def perform(*args, **options)
    @task.michecker_last_job_id = job_id
    @task.user_id = user_id
    @task.save

    @task.log I18n.t('cms.cms/michecker/task.start')

    result = run_html_checker_and_wait
    if result == 0
      @task.log I18n.t('cms.cms/michecker/task.success')
    else
      @task.log I18n.t('cms.cms/michecker/task.failed')
    end

    @task.michecker_last_result = result
    @task.michecker_last_executed_at = Time.zone.now
    @task.save
  end

  private

  def parse_arguments!
    @target_type = arguments[0]

    @target_id = arguments[1]
    raise "malformed target id: #{@target_id}" if @target_id.blank? || !@target_id.numeric?

    case @target_type
    when "page"
      @target = Cms::Page.site(site).find(@target_id)
    when "node"
      @target = Cms::Node.site(site).find(@target_id)
    end
    raise "unknown target type: #{@target_type}" if @target.blank?
  end

  def task_cond
    parse_arguments!

    cond = super
    cond[:target_type] = @target_type
    cond[:target_id] = @target_id
    cond[:target_class] = @target.class.name
    cond
  end

  def new_access_token!
    token = SS::AccessToken.new(cur_user: user)
    token.create_token
    token.save!

    token.token
  end

  def generate_preview_url!
    scheme = site.mypage_scheme.presence || (site.https == "enabled" ? "https" : "http")
    domain = site.mypage_domain.presence || site.domain

    params = {
      protocol: scheme, host: domain,
      site: site.id, path: @target.url[1..-1], "no-controller" => true, access_token: new_access_token!
    }

    Rails.application.routes.url_helpers.cms_preview_url(params)
  end

  def run_html_checker_and_wait
    commands = Array(SS.config.michecker["command"]).compact
    return if commands.blank?

    ::FileUtils.rm_f @task.html_checker_report_filepath
    ::FileUtils.rm_f @task.low_vision_report_filepath
    ::FileUtils.rm_f @task.low_vision_source_filepath
    ::FileUtils.rm_f @task.low_vision_result_filepath

    status = ::Dir.mktmpdir("#{Rails.root}/tmp") do |dir|
      commands = commands.dup
      commands[0] = ::File.expand_path(commands[0], Rails.root)
      commands << "--no-interactive"
      commands << "--html-checker-output-report"
      commands << Cms::Michecker::Result::HTML_CHECKER_REPORT_BASENAME
      commands << "--lowvision-output-report"
      commands << Cms::Michecker::Result::LOW_VISION_REPORT_BASENAME
      commands << "--lowvision-source-image"
      commands << Cms::Michecker::Result::LOW_VISION_SOURCE_BASENAME
      commands << "--lowvision-output-image"
      commands << Cms::Michecker::Result::LOW_VISION_RESULT_BASENAME
      commands << generate_preview_url!

      reader, writer = ::IO.pipe
      pid = spawn(*commands, out: writer.fileno, err: writer.fileno, chdir: dir)
      _, status = Process.waitpid2(pid)

      writer.close
      writer = nil

      Rails.logger.info "==== raw michecker output ===="
      Rails.logger.info reader.read
      Rails.logger.info "==== raw michecker output ===="

      save_results(dir) if status.success?

      status
    ensure
      writer.close if writer
      reader.close if reader
    end

    status.exitstatus
  end

  def save_results(dir)
    save_result "#{dir}/#{Cms::Michecker::Result::HTML_CHECKER_REPORT_BASENAME}", @task.html_checker_report_filepath
    save_result "#{dir}/#{Cms::Michecker::Result::LOW_VISION_REPORT_BASENAME}", @task.low_vision_report_filepath
    save_result "#{dir}/#{Cms::Michecker::Result::LOW_VISION_SOURCE_BASENAME}", @task.low_vision_source_filepath
    save_result "#{dir}/#{Cms::Michecker::Result::LOW_VISION_RESULT_BASENAME}", @task.low_vision_result_filepath
  end

  def save_result(source_file, dest_file)
    return unless ::File.exist?(source_file)

    basedir = ::File.dirname(dest_file)
    ::FileUtils.mkdir_p(basedir) unless ::Dir.exist?(basedir)

    ::FileUtils.cp(source_file, dest_file)
  end
end
