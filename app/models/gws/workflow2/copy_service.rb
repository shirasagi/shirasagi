class Gws::Workflow2::CopyService
  include ActiveModel::Model

  PERMIT_PARAMS = [].freeze

  attr_accessor :cur_site, :cur_group, :cur_user, :type, :item
  attr_reader :new_item

  def call
    new_item = new_clone
    result = new_item.save
    unless result
      SS::Model.copy_errors(new_item, item)
      return result
    end

    @new_item = new_item
    result
  end

  private

  def new_clone
    new_item = item.clone
    new_item.cur_site = cur_site
    new_item.cur_user = cur_user
    if item.form.present?
      new_item.name = item.form.new_file_name
      new_item.destination_group_ids = item.form.destination_group_ids
      new_item.destination_user_ids = item.form.destination_user_ids
    else
      new_item.name = "[#{I18n.t('workflow.cloned_name_prefix')}] #{item.name}".truncate(80)
    end
    new_item.in_clone_file = true if new_item.respond_to?(:in_clone_file=)
    new_item.workflow_user_id = nil
    new_item.workflow_agent_id = nil
    new_item.workflow_state = nil
    new_item.workflow_comment = nil
    new_item.workflow_pull_up = nil
    new_item.workflow_on_remand = nil
    new_item.workflow_approvers = nil
    new_item.workflow_required_counts = nil
    new_item.workflow_approver_attachment_uses = nil
    new_item.workflow_current_circulation_level = nil
    new_item.workflow_circulations = nil
    new_item.workflow_circulation_attachment_uses = nil
    new_item.approved = nil
    if new_item.destination_groups.active.present? || new_item.destination_users.active.present?
      new_item.destination_treat_state = "untreated"
    else
      new_item.destination_treat_state = "no_need_to_treat"
    end
    new_item.user_id = nil
    new_item.user_uid = nil
    new_item.user_name = nil
    new_item.user_group_id = nil
    new_item.user_group_name = nil
    new_item.column_values.each do |column_value|
      if column_value.is_a?(Gws::Column::Value::FileUpload)
        column_value.in_clone_file = true
      end
    end
    new_item
  end
end
