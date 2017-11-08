module Gws::Addon::System::MenuSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :menu_portal_state, type: String, default: 'show'
    field :menu_portal_label, type: String, localize: true

    field :menu_reminder_state, type: String, default: 'show'
    field :menu_reminder_label, type: String, localize: true

    field :menu_schedule_state, type: String, default: 'show'
    field :menu_schedule_label, type: String, localize: true

    field :menu_memo_state, type: String, default: 'show'
    field :menu_memo_label, type: String, localize: true

    field :menu_board_state, type: String, default: 'show'
    field :menu_board_label, type: String, localize: true

    field :menu_question_state, type: String, default: 'show'
    field :menu_question_label, type: String, localize: true

    field :menu_workflow_state, type: String, default: 'show'
    field :menu_workflow_label, type: String, localize: true

    field :menu_report_state, type: String, default: 'show'
    field :menu_report_label, type: String, localize: true

    field :menu_circular_state, type: String, default: 'show'
    field :menu_circular_label, type: String, localize: true

    field :menu_monitor_state, type: String, default: 'show'
    field :menu_monitor_label, type: String, localize: true

    field :menu_share_state, type: String, default: 'show'
    field :menu_share_label, type: String, localize: true

    field :menu_shared_address_state, type: String, default: 'show'
    field :menu_shared_address_label, type: String, localize: true

    field :menu_personal_address_state, type: String, default: 'show'
    field :menu_personal_address_label, type: String, localize: true

    field :menu_staff_record_state, type: String, default: 'show'
    field :menu_staff_record_label, type: String, localize: true

    field :menu_links_state, type: String, default: 'show'
    field :menu_links_label, type: String, localize: true

    field :menu_elasticsearch_state, type: String, default: 'hide'
    field :menu_elasticsearch_label, type: String, localize: true

    field :menu_discussion_forum_state, type: String, default: 'hide'
    field :menu_discussion_forum_label, type: String, localize: true

    permit_params :menu_portal_state,
      :menu_reminder_state,
      :menu_schedule_state,
      :menu_memo_state,
      :menu_board_state,
      :menu_question_state,
      :menu_report_state,
      :menu_workflow_state,
      :menu_circular_state,
      :menu_monitor_state,
      :menu_share_state,
      :menu_shared_address_state,
      :menu_personal_address_state,
      :menu_staff_record_state,
      :menu_links_state,
      :menu_elasticsearch_stat,
      :menu_discussion_forum_state
    permit_params :menu_portal_label,
      :menu_reminder_label,
      :menu_schedule_label,
      :menu_memo_label,
      :menu_board_label,
      :menu_question_label,
      :menu_report_label,
      :menu_workflow_label,
      :menu_circular_label,
      :menu_monitor_label,
      :menu_share_label,
      :menu_shared_address_label,
      :menu_personal_address_label,
      :menu_staff_record_label,
      :menu_links_label,
      :menu_elasticsearch_label,
      :menu_discussion_forum_label
  end

  def menu_state_options
    %w(show hide).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  alias menu_portal_state_options menu_state_options
  alias menu_reminder_state_options menu_state_options
  alias menu_schedule_state_options menu_state_options
  alias menu_memo_state_options menu_state_options
  alias menu_board_state_options menu_state_options
  alias menu_question_state_options menu_state_options
  alias menu_report_state_options menu_state_options
  alias menu_workflow_state_options menu_state_options
  alias menu_circular_state_options menu_state_options
  alias menu_monitor_state_options menu_state_options
  alias menu_share_state_options menu_state_options
  alias menu_shared_address_state_options menu_state_options
  alias menu_personal_address_state_options menu_state_options
  alias menu_staff_record_state_options menu_state_options
  alias menu_links_state_options menu_state_options
  alias menu_elasticsearch_state_options menu_state_options
  alias menu_discussion_forum_state_options menu_state_options

  def menu_portal_visible?
    menu_portal_state == 'show'
  end

  def menu_reminder_visible?
    menu_reminder_state == 'show'
  end

  def menu_schedule_visible?
    menu_schedule_state == 'show'
  end

  def menu_memo_visible?
    menu_memo_state == 'show'
  end

  def menu_board_visible?
    menu_board_state == 'show'
  end

  def menu_question_visible?
    menu_question_state == 'show'
  end

  def menu_report_visible?
    menu_workflow_state == 'show'
  end

  def menu_workflow_visible?
    menu_workflow_state == 'show'
  end

  def menu_circular_visible?
    menu_circular_state == 'show'
  end

  def menu_monitor_visible?
    menu_monitor_state == 'show'
  end

  def menu_share_visible?
    menu_share_state == 'show'
  end

  def menu_shared_address_visible?
    menu_shared_address_state == 'show'
  end

  def menu_personal_address_visible?
    menu_personal_address_state == 'show'
  end

  def menu_staff_record_visible?
    menu_staff_record_state == 'show'
  end

  def menu_links_visible?
    menu_links_state == 'show'
  end

  def menu_elasticsearch_visible?
    menu_elasticsearch_state == 'show'
  end

  def menu_discussion_forum_visible?
    menu_discussion_forum_state == 'show'
  end
end
