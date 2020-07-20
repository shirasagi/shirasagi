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
      @target = Cms::Page.site(site).find(@target_id).becomes_with_route
    when "node"
      @target = Cms::Node.site(site).find(@target_id).becomes_with_route
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
    commands = Array(SS.config.cms.michecker["command"]).compact
    return if commands.blank?

    commands = commands.dup
    commands << "--no-interactive"
    commands << "--html-checker-output-report"
    commands << @task.html_checker_report_filepath
    commands << "--lowvision-output-report"
    commands << @task.low_vision_report_filepath
    commands << "--lowvision-source-image"
    commands << @task.low_vision_source_filepath
    commands << "--lowvision-output-image"
    commands << @task.low_vision_result_filepath
    commands << generate_preview_url!

    pid = spawn(*commands)
    _, status = Process.waitpid2(pid)

    status.exitstatus
  end
end
