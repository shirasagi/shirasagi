class Gws::Tabular::File::CopyService
  include ActiveModel::Model

  PERMIT_PARAMS = SS::EMPTY_ARRAY

  attr_accessor :cur_site, :cur_group, :cur_user, :cur_form, :cur_release, :item, :overwrites
  attr_reader :new_item

  def build
    new_item = item.clone
    new_item.site = new_item.cur_site = cur_site
    new_item.user = new_item.cur_user = cur_user
    set_user_reference_defaults(new_item)

    if cur_form.workflow_enabled?
      set_workflow_defaults(new_item)
    end

    @new_item = new_item
  end

  def save
    build
    if overwrites.present?
      new_item.attributes = overwrites
    end

    new_item.save
  end

  private

  def set_user_reference_defaults(new_item)
    # Gws::Reference::User#set_user_id が適切に動作するようにするため、フィールドを適切にクリアする
    new_item.user_id   = nil
    new_item.user_uid  = nil
    new_item.user_name = nil

    new_item.user_group_id   = nil
    new_item.user_group_name = nil

    new_item
  end

  def set_workflow_defaults(new_item)
    # Gws::Addon::Tabular::DestinationState / Gws::Workflow2::DestinationState / Gws::Workflow2::DestinationSetting
    if cur_form.destination_groups.active.present? || cur_form.destination_users.active.present?
      new_item.destination_treat_state = "untreated"
    else
      new_item.destination_treat_state = "no_need_to_treat"
    end
    new_item.destination_group_ids = cur_form.destination_group_ids
    new_item.destination_user_ids = cur_form.destination_user_ids
    # Gws::Addon::Tabular::Approver / Gws::Workflow2::Approver / Workflow::Approver
    new_item.workflow_user_id = nil
    new_item.workflow_agent_id = nil
    new_item.workflow_state = nil
    new_item.workflow_kind = nil
    new_item.workflow_comment = nil
    new_item.workflow_pull_up = nil
    new_item.workflow_on_remand = nil
    new_item.workflow_approvers = []
    new_item.workflow_required_counts = []
    new_item.workflow_approver_attachment_uses = []
    new_item.workflow_current_circulation_level = 0
    new_item.workflow_circulations = []
    new_item.workflow_circulation_attachment_uses = []
    new_item.approved = nil
    new_item.workflow_reminder_sent_at = nil

    new_item
  end
end
