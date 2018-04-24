class Gws::Workflow::PagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  prepend_view_path "app/views/workflow/pages"

  before_action :set_item, only: %i[request_update approve_update pull_up_update remand_update branch_create]

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
    current_workflow_approvers = @item.workflow_approvers_at(current_level)
    current_workflow_approvers.each do |workflow_approver|
      args = { f_uid: @item.workflow_user_id, t_uid: workflow_approver[:user_id],
               site: @cur_site, page: @item,
               url: params[:url], comment: params[:workflow_comment] }
      Workflow::Mailer.request_mail(args).deliver_now if validate_domain(args[:t_uid])

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

    @item.workflow_user_id = @cur_user._id
    @item.workflow_state   = "request"
    @item.workflow_comment = params[:workflow_comment]
    @item.workflow_pull_up = params[:workflow_pull_up]
    @item.workflow_on_resume = params[:workflow_on_resume]
    @item.workflow_approvers = params[:workflow_approvers]
    @item.workflow_required_counts = params[:workflow_required_counts]

    if @item.valid?
      request_approval
      render json: { workflow_state: @item.workflow_state }
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def approve_update
    raise "403" unless @item.allowed?(:approve, @cur_user)

    save_level = @item.workflow_current_level
    if params[:action] == 'pull_up_update'
      @item.pull_up_workflow_approver_state(@cur_user, @model::WORKFLOW_STATE_APPROVE, params[:remand_comment])
    else
      @item.update_current_workflow_approver_state(@cur_user, @model::WORKFLOW_STATE_APPROVE, params[:remand_comment])
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
      if validate_domain(@item.workflow_user_id)
        Workflow::Mailer.send_approve_mails(
          f_uid: @cur_user._id, t_uids: [ @item.workflow_user_id ],
          site: @cur_site, page: @item,
          url: params[:url], comment: params[:remand_comment]
        )
      end

      Gws::Memo::Notifier.deliver_workflow_approve!(
        cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
        to_users: Gws::User.where(id: @item.workflow_user_id), item: @item,
        url: params[:url], comment: params[:remand_comment]
      ) rescue nil

      if @item.try(:branch?) && @item.state == "public"
        @item.delete
      end
    end

    render json: { workflow_state: workflow_state }
  end

  alias pull_up_update approve_update

  def remand_update
    raise "403" unless @item.allowed?(:approve, @cur_user)

    @item.workflow_state = @model::WORKFLOW_STATE_REMAND
    @item.update_current_workflow_approver_state(@cur_user, @model::WORKFLOW_STATE_REMAND, params[:remand_comment])

    if @item.update
      if @item.workflow_state == "remand"
        args = { f_uid: @cur_user._id, t_uid: @item.workflow_user_id,
                 site: @cur_site, page: @item,
                 url: params[:url], comment: params[:remand_comment] }
        Workflow::Mailer.remand_mail(args).deliver_now if validate_domain(args[:t_uid])
        Gws::Memo::Notifier.deliver_workflow_remand!(
          cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
          to_users: Gws::User.where(id: @item.workflow_user_id), item: @item,
          url: params[:url], comment: params[:remand_comment]
        ) rescue nil
      end
      render json: { workflow_state: @item.workflow_state }
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
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
end
