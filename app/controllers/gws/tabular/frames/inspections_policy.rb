class Gws::Tabular::Frames::InspectionsPolicy
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_group, :cur_user, :model, :item

  def update?
    return false if item.deleted?
    return false if item.workflow_state != "request"

    workflow_approver = item.find_workflow_request_to(cur_user)
    return false unless workflow_approver

    workflow_state = workflow_approver[:state]
    return false if workflow_state != 'request' && workflow_state != 'pending'

    true
  end
  alias edit? update?

  def file_attachment?
    return false if item.deleted?
    return false if item.workflow_state != "request"

    workflow_approver = @item.find_workflow_request_to(@cur_user)
    return false unless workflow_approver

    workflow_state = workflow_approver[:state]
    return false if workflow_state != 'request' && workflow_state != 'pending'

    @item.workflow_approver_attachment_enabled_at?(workflow_approver[:level])
  end

  def reroute_myself?
    return false if item.deleted?
    return false unless cur_user.gws_role_permit_any?(cur_site, :reroute_private_riken_recycle_boards)

    workflow_approver = item.find_workflow_request_to(cur_user)
    return false unless workflow_approver

    workflow_state = workflow_approver[:state]
    return false if workflow_state != 'request' && workflow_state != 'pending'

    true
  end
end
