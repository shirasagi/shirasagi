module Gws::Addon::System::NoticeSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    %w(schedule todo report workflow circular monitor board faq qna survey discussion announcement).each do |name|
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
    try("notice_#{function}_state") == 'force_silence'
  end

  def notify_model?(model)
    function = case model.model_name.i18n_key
      when :"gws/board/topic", :"gws/board/post" then 'board'
      when :"gws/circular/post" then 'circular'
      when :"gws/faq/topic", :"gws/faq/post" then 'faq'
      when :"gws/qna/topic", :"gws/qna/post" then 'qna'
      when :"gws/schedule/todo" then 'todo'
      when :"gws/schedule/plan", :"gws/schedule/comment", :"gws/schedule/attendance", :"gws/schedule/approval" then 'schedule'
      when :"gws/discussion/topic", :"gws/discussion/post" then 'discussion'
      when :"gws/workflow/file"  then 'workflow'
      when :"gws/report/file" then 'report'
      when :"gws/notice/post" then 'announcement'
      when :"gws/survey/form", :"gws/survey/file" then 'survey'
      when :"gws/monitor/topic", :"gws/monitor/post" then 'monitor'
    end
    !force_silence?(function)
  end

  def allow_send_mail?
    send_notice_email_state == "allow"
  end
end
