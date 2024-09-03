module Gws::Addon::System::NoticeSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  MODEL_FUNCTION_MAP = begin
    map = {}

    %w(gws/board/topic gws/board/post).each { |k| map[k] = 'board' }
    %w(gws/circular/post).each { |k| map[k] = 'circular' }
    %w(gws/faq/topic gws/faq/post).each { |k| map[k] = 'faq' }
    %w(gws/qna/topic gws/qna/post).each { |k| map[k] = 'qna' }
    %w(gws/schedule/todo).each { |k| map[k] = 'todo' }
    %w(gws/workload/work).each { |k| map[k] = 'workload' }
    %w(
      gws/schedule/plan gws/schedule/comment gws/schedule/todo_comment
      gws/schedule/attendance gws/schedule/approval).each { |k| map[k] = 'schedule' }
    %w(gws/discussion/topic gws/discussion/post).each { |k| map[k] = 'discussion' }
    %w(gws/workflow/file gws/workflow2/file).each { |k| map[k] = 'workflow' }
    %w(gws/report/file).each { |k| map[k] = 'report' }
    %w(gws/notice/post).each { |k| map[k] = 'announcement' }
    %w(gws/survey/form gws/survey/file).each { |k| map[k] = 'survey' }
    %w(gws/monitor/topic gws/monitor/post).each { |k| map[k] = 'monitor' }
    %w(gws/affair/overtime_file gws/affair/leave_file gws/affair/compensatory_file).each { |k| map[k] = 'affair' }

    map.freeze
  end

  included do
    Gws::Addon::System::NoticeSetting::MODEL_FUNCTION_MAP.values.uniq.sort.each do |name|
      field "notice_#{name}_state", type: String, default: 'notify'
      permit_params "notice_#{name}_state"
      alias_method("notice_#{name}_state_options", "notice_state_options")
    end

    field :send_notice_email_state, type: String, default: 'allow'
    permit_params :send_notice_email_state
  end

  def notice_state_options
    %w(notify force_silence).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def send_notice_email_state_options
    %w(allow deny).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def force_silence?(function)
    return true unless function
    try("notice_#{function}_state") == 'force_silence'
  end

  def notify_model?(model)
    function = MODEL_FUNCTION_MAP[model.model_name.i18n_key.to_s]
    !force_silence?(function)
  end

  def allow_send_mail?
    send_notice_email_state == "allow"
  end
end
