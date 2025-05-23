class Workflow::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :set_item, only: %i[request_update restart_update approve_update pull_up_update remand_update branch_create]

  %i[request_update restart_update approve_update pull_up_update remand_update request_cancel branch_update].tap do |names|
    after_action :create_history_log, only: names
  end

  private

  def set_model
    @model = Cms::Page
  end

  def set_item
    @item = @model.find(params[:id])
    @item.attributes = fix_params
    @item.try(:allow_other_user_files)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
  end

  def create_history_log
    # レスポンスの status コードが 200 か 422 の場合、操作履歴が作られないので、手動で作成
    self.class.log_class.create_log!(
      request, response,
      controller: params[:controller], action: params[:action],
      cur_site: @cur_site, cur_user: @cur_user, item: @item
    ) rescue nil
  end

  def request_approval
    current_level = @item.workflow_current_level
    current_workflow_approvers = @item.workflow_pull_up_approvers_at(current_level)
    Workflow::Mailer.send_request_mails(
      f_uid: @item.workflow_user_id, t_uids: current_workflow_approvers.map { |approver| approver[:user_id] },
      site: @cur_site, page: @item,
      url: params[:url], comment: @item.workflow_comment
    )

    @item.set_workflow_approver_state_to_request
    @item.record_timestamps = false
    # 更新履歴が作成されるように変更する
    # @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    @item.save
  end

  def workflow_alert
    email_blank_users = []
    target_user = nil
    email_blank_users.push(@cur_user.name) if @cur_user.email.blank?
    if params[:workflow_approvers].present?
      params[:workflow_approvers].each do |workflow_approver|
        element = workflow_approver.split(",")
        target_user = SS::User.find(element[1]) rescue nil
        if target_user
          email_blank_users.push(target_user.name) if target_user.email.blank?
        end
      end
    else
      current_level = @item.workflow_current_level
      current_workflow_approvers = @item.workflow_approvers_at(current_level)
      current_workflow_approvers.each do |workflow_approver|
        target_user = SS::User.find(workflow_approver[:user_id]) rescue nil
        if target_user
          email_blank_users.push(target_user.name) if target_user.email.blank?
        end
      end
      target_user = nil
      target_user_id = @item.workflow_user_id || @cur_user._id
      target_user = SS::User.find(target_user_id) rescue nil
      if target_user
        email_blank_users.push(target_user.name) if target_user.email.blank?
      end
    end
    email_blank_users.uniq!
    email_blank_users.sort!
    return nil if email_blank_users.blank?
    message = t("errors.messages.user_email_blank")
    email_blank_users.each do |email_blank_user|
      message += "\n#{email_blank_user}"
    end
    message
  end

  def create_success_response
    json = { workflow_state: @item.workflow_state }

    redirect = json[:redirect] = {}
    redirect[:reload] = params[:id].to_i == @item.id
    redirect[:show] = @item.private_show_path
    redirect[:url] = @item.url

    json
  end

  public

  def request_update
    raise "403" unless @item.allowed?(:edit, @cur_user)

    if params[:forced_update_option] == "false"
      if message = workflow_alert
        render json: { workflow_alert: message }
        return
      end
    end

    @item.record_timestamps = false
    # 一時保存のため、履歴を作成しないようにする（履歴に記録したい保存は request_approval で行われる）
    @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    @item.approved = nil
    @item.workflow_user_id = @cur_user.id
    @item.workflow_state = @model::WORKFLOW_STATE_REQUEST
    @item.workflow_kind = params[:workflow_kind]
    @item.workflow_comment = params[:workflow_comment]
    @item.workflow_pull_up = params[:workflow_pull_up].present? ? params[:workflow_pull_up] : 'disabled'
    @item.workflow_on_remand = params[:workflow_on_remand]
    @item.workflow_approvers = params[:workflow_approvers]
    @item.workflow_required_counts = params[:workflow_required_counts]
    @item.workflow_current_circulation_level = 0
    @item.workflow_circulations = params[:workflow_circulations]
    result = @item.save
    @item.skip_history_backup = false if @item.respond_to?(:skip_history_backup)

    if result
      request_approval
      render json: create_success_response
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def restart_update
    raise "403" unless @item.allowed?(:edit, @cur_user)

    @item.record_timestamps = false
    # 一時保存のため、履歴を作成しないようにする（履歴に記録したい保存は request_approval で行われる）
    @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    @item.approved = nil
    @item.workflow_user_id = @cur_user.id
    @item.workflow_state = @model::WORKFLOW_STATE_REQUEST
    @item.workflow_kind = params[:workflow_kind]
    @item.workflow_comment = params[:workflow_comment]
    copy = @item.workflow_approvers.to_a
    copy.each do |approver|
      approver[:state] = @model::WORKFLOW_STATE_PENDING
      approver[:comment] = ''
      approver.delete(:created)
    end
    @item.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    @item.workflow_current_circulation_level = 0
    copy = @item.workflow_circulations.to_a
    copy.each do |circulation|
      circulation[:state] = @model::WORKFLOW_STATE_PENDING
      circulation[:comment] = ''
    end
    @item.workflow_circulations = Workflow::Extensions::WorkflowCirculations.new(copy)
    result = @item.save
    @item.skip_history_backup = false if @item.respond_to?(:skip_history_backup)

    if result
      request_approval
      render json: create_success_response
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def approve_update
    raise "403" unless @item.allowed?(:approve, @cur_user)

    if params[:forced_update_option] == "false"
      if message = workflow_alert
        render json: { workflow_alert: message }
        return
      end
    end

    save_level = @item.workflow_current_level
    if params[:action] == 'pull_up_update'
      @item.pull_up_workflow_approver_state(@cur_user, comment: params[:remand_comment])
    else
      @item.approve_workflow_approver_state(@cur_user, comment: params[:remand_comment])
    end

    @item.record_timestamps = false
    # 更新履歴が作成されるように変更する
    # @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    if @item.finish_workflow?
      @item.approved = Time.zone.now
      @item.workflow_state = @model::WORKFLOW_STATE_APPROVE
      case @item.workflow_kind
      when 'public', 'closed'
        @item.state = @item.workflow_kind
      else
        @item.state = 'public'
      end
      @item.record_timestamps = true
      # @item.skip_history_backup = false if @item.respond_to?(:skip_history_backup)

      if @item.respond_to?(:release_date)
        if @item.release_date
          @item.state = "ready"
        else
          @item.release_date = nil
        end
      end
    end
    if @item.state_changed? && @item.state == "public" && @item.try(:master_id).present?
      task = SS::Task.find_or_create_for_model(@item.master, site: @cur_site)
      rejected = -> { @item.errors.add :base, :other_task_is_running }
      guard = ->(&block) do
        task.run_with(rejected: rejected) do
          task.log "# #{I18n.t("workflow.branch_page")} #{I18n.t("ss.buttons.publish_save")}"
          task.log "master: #{@item.master.filename}(#{@item.master_id})"
          task.log "branch: #{@item.filename}(#{@item.id})"
          block.call
        end
      end
    else
      # this means "no guard"
      guard = ->(&block) { block.call }
    end

    result = nil
    guard.call do
      result = @item.save
    end

    if result
      task.log "succeeded" if task
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
      task.log "failed\n#{@item.errors.full_messages.join("\n")}" if task
      return
    end

    merged = false
    if @item.workflow_state == @model::WORKFLOW_STATE_APPROVE && @item.try(:branch?) && @item.state == "public"
      save = @item.master
      @item.file_ids = nil if @item.respond_to?(:file_ids)
      @item.skip_history_trash = true if @item.respond_to?(:skip_history_trash)
      @item.destroy
      @item = save
      merged = true
    end

    current_level = @item.workflow_current_level
    if save_level != current_level
      # escalate workflow
      request_approval
    end

    if @item.workflow_state == @model::WORKFLOW_STATE_APPROVE
      # finished workflow
      url = merged ? @item.private_show_path : params[:url].to_s
      Workflow::Mailer.send_approve_mails(
        f_uid: @cur_user._id, t_uids: [ @item.workflow_user_id ],
        site: @cur_site, page: @item,
        url: url, comment: params[:remand_comment]
      )
    end

    render json: create_success_response
  end

  alias pull_up_update approve_update

  def remand_update
    raise "403" unless @item.allowed?(:approve, @cur_user)

    if params[:forced_update_option] == "false"
      if message = workflow_alert
        render json: { workflow_alert: message }
        return
      end
    end

    @item.remand_workflow_approver_state(@cur_user, comment: params[:remand_comment])
    @item.record_timestamps = false
    # 更新履歴が作成されるように変更する
    # @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    begin
      recipients = []
      if @item.workflow_state == @model::WORKFLOW_STATE_REMAND
        recipients << @item.workflow_user_id
      else
        prev_level_approvers = @item.workflow_approvers_at(@item.workflow_current_level)
        recipients += prev_level_approvers.map { |hash| hash[:user_id] }
      end

      Workflow::Mailer.send_remand_mails(
        f_uid: @cur_user._id, t_uids: recipients,
        site: @cur_site, page: @item,
        url: params[:url], comment: params[:remand_comment]
      )
    end
    render json: create_success_response
  end

  def request_cancel
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user)

    return if request.get? || request.head?

    @item.approved = nil
    # @item.workflow_user_id = nil
    @item.workflow_state = @model::WORKFLOW_STATE_CANCELLED

    @item.record_timestamps = false
    # 更新履歴が作成されるように変更する
    # @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    if @item.save
      render json: { notice: t('workflow.notice.request_cancelled') }
    else
      render json: { workflow_alert: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def branch_create
    raise "400" if @item.branch?

    @item.cur_node = @item.parent
    service = Workflow::BranchCreationService.new(cur_site: @cur_site, item: @item)
    result = service.call
    return unless result

    @items = @item.branches
    render :branch, layout: false
  end
end
