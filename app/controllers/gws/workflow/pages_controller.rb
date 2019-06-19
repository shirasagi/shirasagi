class Gws::Workflow::PagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  prepend_view_path "app/views/workflow/pages"

  before_action :set_item,
                only: %i[request_update restart_update approve_update pull_up_update remand_update branch_create seen_update]

  private

  def set_model
    @model = Gws::Workflow::File
  end

  def set_item
    @item = @model.find(params[:id]) #.becomes_with_route
    @item.attributes = fix_params
    @item.try(:allow_other_user_files)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def validate_domain(user_id)
    email = SS::User.find(user_id).email
    @cur_site.email_domain_allowed?(email)
  end

  def request_approval
    current_level = @item.workflow_current_level
    current_workflow_approvers = @item.workflow_approvers_at(current_level).reject{|approver| approver[:user_id] == @cur_user.id}
    current_workflow_approvers.each do |workflow_approver|
      Gws::Memo::Notifier.deliver_workflow_request!(
        cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
        to_users: Gws::User.where(id: workflow_approver[:user_id]), item: @item,
        url: params[:url], comment: params[:workflow_comment]
      ) rescue nil
    end

    @item.set_workflow_approver_state_to_request
    @item.update
  end

  public

  def request_update
    raise "403" unless @item.allowed?(:edit, @cur_user)
    if @item.workflow_requested?
      raise "403" unless @item.allowed?(:reroute, @cur_user)
    end

    @item.approved = nil
    if params[:workflow_agent_type].to_s == "agent"
      @item.workflow_user_id = Gws::User.site(@cur_site).in(id: params[:workflow_users]).first.id
      @item.workflow_agent_id = @cur_user.id
    else
      @item.workflow_user_id = @cur_user.id
      @item.workflow_agent_id = nil
    end
    @item.workflow_state   = @model::WORKFLOW_STATE_REQUEST
    @item.workflow_comment = params[:workflow_comment]
    @item.workflow_pull_up = params[:workflow_pull_up]
    @item.workflow_on_remand = params[:workflow_on_remand]
    save_workflow_approvers = @item.workflow_approvers
    @item.workflow_approvers = params[:workflow_approvers]
    @item.workflow_required_counts = params[:workflow_required_counts]
    @item.workflow_approver_attachment_uses = params[:workflow_approver_attachment_uses]
    @item.workflow_current_circulation_level = 0
    save_workflow_circulations = @item.workflow_circulations
    @item.workflow_circulations = params[:workflow_circulations]
    @item.workflow_circulation_attachment_uses = params[:workflow_circulation_attachment_uses]

    if @item.valid?
      request_approval
      @item.class.destroy_workflow_files(save_workflow_approvers)
      @item.class.destroy_workflow_files(save_workflow_circulations)
      render json: { workflow_state: @item.workflow_state }
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def restart_update
    raise "403" unless @item.allowed?(:edit, @cur_user)

    @item.approved = nil
    if params[:workflow_agent_type].to_s == "agent"
      @item.workflow_user_id = Gws::User.site(@cur_site).in(id: params[:workflow_users]).first.id
      @item.workflow_agent_id = @cur_user.id
    else
      @item.workflow_user_id = @cur_user.id
      @item.workflow_agent_id = nil
    end
    @item.workflow_state = @model::WORKFLOW_STATE_REQUEST
    @item.workflow_comment = params[:workflow_comment]
    save_workflow_approvers = @item.workflow_approvers
    copy = @item.workflow_approvers.to_a
    copy.each do |approver|
      approver[:state] = @model::WORKFLOW_STATE_PENDING
      approver[:comment] = ''
      approver[:file_ids] = nil
    end
    @item.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    @item.workflow_current_circulation_level = 0
    save_workflow_circulations = @item.workflow_circulations
    copy = @item.workflow_circulations.to_a
    copy.each do |circulation|
      circulation[:state] = @model::WORKFLOW_STATE_PENDING
      circulation[:comment] = ''
      circulation[:file_ids] = nil
    end
    @item.workflow_circulations = Workflow::Extensions::WorkflowCirculations.new(copy)

    if @item.save
      request_approval
      @item.class.destroy_workflow_files(save_workflow_approvers)
      @item.class.destroy_workflow_files(save_workflow_circulations)
      render json: { workflow_state: @item.workflow_state }
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def approve_update
    raise "403" unless @item.allowed?(:approve, @cur_user)

    save_level = @item.workflow_current_level
    comment = params[:remand_comment]
    file_ids = params[:workflow_file_ids]
    opts = { comment: comment, file_ids: file_ids }
    if params[:action] == 'pull_up_update'
      @item.pull_up_workflow_approver_state(@cur_user, opts)
    else
      @item.approve_workflow_approver_state(@cur_user, opts)
    end

    if @item.finish_workflow?
      @item.approved = Time.zone.now
      @item.workflow_state = @model::WORKFLOW_STATE_APPROVE
      @item.state = "approve"
    end

    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end

    current_level = @item.workflow_current_level
    if save_level != current_level
      # escalate workflow
      request_approval
    end

    workflow_state = @item.workflow_state
    if workflow_state == @model::WORKFLOW_STATE_APPROVE
      # finished workflow
      to_user_ids = ([ @item.workflow_user_id, @item.workflow_agent_id ].compact) - [@cur_user.id]
      if to_user_ids.present?
        notify_user_ids = to_user_ids.select{|user_id| Gws::User.find(user_id).use_notice?(@item)}.uniq
        if notify_user_ids.present?
          Gws::Memo::Notifier.deliver_workflow_approve!(
            cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
            to_users: Gws::User.in(id: notify_user_ids),
            item: @item, url: params[:url], comment: params[:remand_comment]
          ) rescue nil
        end
      end

      if @item.move_workflow_circulation_next_step
        current_circulation_users = @item.workflow_current_circulation_users.nin(id: @cur_user.id).active
        current_circulation_users = current_circulation_users.select{|user| user.use_notice?(@item)}
        if current_circulation_users.present?
          Gws::Memo::Notifier.deliver_workflow_circulations!(
            cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
            to_users: current_circulation_users, item: @item,
            url: params[:url], comment: params[:remand_comment]
          ) rescue nil
        end
        @item.save
      end

      if @item.try(:branch?) && @item.state == "public"
        @item.delete
      end
    end

    render json: { workflow_state: workflow_state }
  end

  alias pull_up_update approve_update

  def remand_update
    raise "403" unless @item.allowed?(:approve, @cur_user)

    @item.remand_workflow_approver_state(@cur_user, params[:remand_comment])
    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end

    begin
      recipients = []
      if @item.workflow_state == @model::WORKFLOW_STATE_REMAND
        recipients << @item.workflow_user_id
        recipients << @item.workflow_agent_id if @item.workflow_agent_id.present?
      else
        prev_level_approvers = @item.workflow_approvers_at(@item.workflow_current_level)
        recipients += prev_level_approvers.map { |hash| hash[:user_id] }
      end
      recipients -= [@cur_user.id]

      notify_user_ids = recipients.select{|user_id| Gws::User.find(user_id).use_notice?(@item)}.uniq
      if notify_user_ids.present?
        Gws::Memo::Notifier.deliver_workflow_remand!(
          cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
          to_users: Gws::User.and_enabled.in(id: notify_user_ids), item: @item,
          url: params[:url], comment: params[:remand_comment]
        ) rescue nil
      end
    end
    render json: { workflow_state: @item.workflow_state }
  end

  def branch_create
    raise "400" if @item.branch?

    @item.cur_node = @item.parent
    if @item.branches.blank?
      copy = @item.new_clone
      copy.master = @item
      copy.save
    end

    @items = @item.branches
    render :branch, layout: "ss/ajax"
  end

  def seen_update
    comment = params[:remand_comment]
    file_ids = params[:workflow_file_ids]

    if !@item.update_current_workflow_circulation_state(@cur_user, "seen", comment: comment, file_ids: file_ids)
      @item.errors.add :base, :unable_to_update_cirulaton_state
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    to_users = ([ @item.workflow_user, @item.workflow_agent ].compact) - [@cur_user]
    to_users.select!{|user| user.use_notice?(@item)}

    if (comment.present? || file_ids.present?) && to_users.present?
      Gws::Memo::Notifier.deliver_workflow_comment!(
        cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
        to_users: to_users, item: @item,
        url: params[:url], comment: comment
      )
    end

    if @item.workflow_current_circulation_completed? && @item.move_workflow_circulation_next_step
      current_circulation_users = @item.workflow_current_circulation_users.nin(id: @cur_user.id).active
      current_circulation_users = current_circulation_users.select{|user| user.use_notice?(@item)}
      if current_circulation_users.present?
        Gws::Memo::Notifier.deliver_workflow_circulations!(
          cur_site: @cur_site, cur_group: @cur_group, cur_user: @item.workflow_user,
          to_users: current_circulation_users, item: @item,
          url: params[:url], comment: comment
        )
      end
    end

    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    render json: { workflow_state: @item.workflow_state }
  end
end
