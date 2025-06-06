class Gws::Tabular::Frames::ApproversPolicy
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_group, :cur_user, :model, :item

  SHOW_PREDICATORS = %i[item_author? item_approver? item_circular? item_destination?].freeze

  def show?
    case show_template
    when "edit"
      edit?
    else # "show", "cloned_name"
      return false unless SHOW_PREDICATORS.any? { |predicator| send(predicator) }
      true
    end
  end

  def update?
    return false if item.deleted?
    return false unless item_author?
    true
  end
  alias edit? update?

  def restart?
    return false if item.workflow_state != model::WORKFLOW_STATE_REMAND && item.workflow_state != model::WORKFLOW_STATE_CANCELLED
    return false if item.deleted?
    return false unless item_author?
    return false if route_options.blank?
    true
  end

  def cancel?
    return false if item.deleted?
    return false unless @item.workflow_requested?
    return false unless item_author?
    true
  end

  def show_template
    @show_template ||= begin
      if item.try(:cloned_name?) && item.readable?(@cur_user, site: @cur_site)
        "cloned_name"
      elsif item.workflow_state.blank? && item.allowed?(:edit, cur_user, site: cur_site, adds_error: false)
        "edit"
      elsif item.form.readable?(cur_user, site: cur_site)
        "show"
      end
    end
  end

  def route_options
    @route_options ||= Gws::Workflow::Route.route_options(cur_user, cur_site: cur_site, item: item)
  end

  private

  def item_author?
    item.user_id == cur_user.id || item.workflow_user_id == cur_user.id || item.workflow_agent_id == cur_user.id
  end

  def item_approver?
    item.workflow_approvers.any? { |workflow_approver| workflow_approver[:user_id] == cur_user.id }
  end

  def item_circular?
    item.workflow_circulations.any? { |workflow_circulation| workflow_circulation[:user_id] == cur_user.id }
  end

  def item_destination?
    item.destination_user_ids.include?(cur_user.id) || item.destination_group_ids.include?(cur_group.id)
  end
end
