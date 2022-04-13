module Gws::Affair::WorkflowFilter
  extend ActiveSupport::Concern

  private

  def request_approval
    url = request.base_url + params[:url]
    comment = params[:workflow_comment]
    notifier = Gws::Affair::Notifier.new(@item)

    current_level = @item.workflow_current_level
    current_workflow_approvers = @item.workflow_approvers_at(current_level).
      reject { |approver| approver[:user_id] == @cur_user.id }
    current_workflow_approvers.each do |workflow_approver|

      # deliver_workflow_request
      to_users = Gws::User.where(id: workflow_approver[:user_id]).to_a
      notifier.deliver_workflow_request(to_users, url: url, comment: comment)
    end

    @item.set_workflow_approver_state_to_request
    @item.update
  end

  public

  def request_update
    set_item

    raise "403" if !@item.allowed?(:edit, @cur_user)
    raise "403" if @item.workflow_requested? && !@item.allowed?(:reroute, @cur_user)

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
    set_item

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
    set_item

    raise "403" unless @item.allowed?(:approve, @cur_user)

    save_level = @item.workflow_current_level
    comment = params[:remand_comment]
    file_ids = params[:workflow_file_ids]
    delegator_id = params[:workflow_delegator_id]
    if delegator_id.present?
      delegator = @item.class.approver_user_class.site(@cur_site).active.find(delegator_id) rescue nil
    end
    opts = { comment: comment, file_ids: file_ids }
    opts[:delegatee] = @cur_user if delegator
    if params[:action] == 'pull_up_update'
      @item.pull_up_workflow_approver_state(delegator || @cur_user, opts)
    else
      @item.approve_workflow_approver_state(delegator || @cur_user, opts)
    end

    if @item.finish_workflow?
      @item.approved = Time.zone.now
      @item.workflow_state = @model::WORKFLOW_STATE_APPROVE
      @item.state = "approve"
    end

    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    current_level = @item.workflow_current_level
    if save_level != current_level
      # escalate workflow
      request_approval
    end

    workflow_state = @item.workflow_state
    if workflow_state == @model::WORKFLOW_STATE_APPROVE
      # finished workflow
      to_user_ids = [ @item.workflow_user_id, @item.workflow_agent_id ].compact - [ @cur_user.id ]
      to_users = Gws::User.and_enabled.in(id: to_user_ids).select { |user| user.use_notice?(@item) }.to_a

      if to_users.present?
        # deliver_workflow_approve
        url = request.base_url + params[:url]
        comment = params[:remand_comment]

        notifier = Gws::Affair::Notifier.new(@item)
        notifier.deliver_workflow_approve(to_users, url: url, comment: comment)
      end

      if @item.move_workflow_circulation_next_step
        current_circulation_users = @item.workflow_current_circulation_users.nin(id: @cur_user.id).active
        current_circulation_users = current_circulation_users.select { |user| user.use_notice?(@item) }
        if current_circulation_users.present?

          # deliver_workflow_circulations
          url = request.base_url + params[:url]
          comment = params[:remand_comment]

          notifier = Gws::Affair::Notifier.new(@item)
          notifier.deliver_workflow_circulations(current_circulation_users, url: url, comment: comment)

        end
        @item.save
      end

      if @item.try(:branch?) && @item.state == "public"
        @item.delete
      end
    end

    if @item.state == "approve"
      set_week_in_leave_file(@item)
      set_week_out_leave_file(@item)
      set_holiday_leave_file(@item)
    end

    render json: { workflow_state: workflow_state }
  end

  alias pull_up_update approve_update

  def approve_all
    @items = @model.in(id: params[:ids]).to_a
    @items.each do |item|
      item.cur_site = @cur_site
      next unless item.allowed?(:approve, @cur_user)

      save_level = item.workflow_current_level
      item.approve_workflow_approver_state(@cur_user, {})

      if item.finish_workflow?
        item.approved = Time.zone.now
        item.workflow_state = @model::WORKFLOW_STATE_APPROVE
        item.state = "approve"
      end
      next if !item.save

      notify_url = ::File.join(request.base_url, item.private_show_path)
      current_level = item.workflow_current_level
      if save_level != current_level
        # escalate workflow
        notifier = Gws::Affair::Notifier.new(item)
        current_level = item.workflow_current_level
        current_workflow_approvers = item.workflow_approvers_at(current_level).
          reject { |approver| approver[:user_id] == @cur_user.id }
        current_workflow_approvers.each do |workflow_approver|
          # deliver_workflow_request
          to_users = Gws::User.where(id: workflow_approver[:user_id]).to_a
          notifier.deliver_workflow_request(to_users, url: notify_url)
        end

        item.set_workflow_approver_state_to_request
        item.update
      end

      workflow_state = item.workflow_state
      if workflow_state == @model::WORKFLOW_STATE_APPROVE
        # finished workflow
        to_user_ids = [ @item.workflow_user_id, @item.workflow_agent_id ].compact - [ @cur_user.id ]
        to_users = Gws::User.and_enabled.in(id: to_user_ids).select { |user| user.use_notice?(item) }.to_a

        if to_users.present?
          # deliver_workflow_approve
          notifier = Gws::Affair::Notifier.new(item)
          notifier.deliver_workflow_approve(to_users, url: notify_url)
        end

        if item.move_workflow_circulation_next_step
          current_circulation_users = item.workflow_current_circulation_users.nin(id: @cur_user.id).active
          current_circulation_users = current_circulation_users.select { |user| user.use_notice?(item) }
          if current_circulation_users.present?
            # deliver_workflow_circulations
            notifier = Gws::Affair::Notifier.new(item)
            notifier.deliver_workflow_circulations(current_circulation_users, url: notify_url)
          end
          item.save
        end
      end

      next if item.state != "approve"
      set_week_in_leave_file(item)
      set_week_out_leave_file(item)
      set_holiday_leave_file(item)
    end

    respond_to do |format|
      format.html { redirect_to({ action: :index }, notice: I18n.t("ss.notice.approved_all")) }
      format.json { head :no_content }
    end
  end

  def remand_update
    set_item

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
        recipients += prev_level_approvers.pluck(:user_id)
      end
      recipients -= [@cur_user.id]

      to_users = Gws::User.and_enabled.in(id: recipients).select { |user| user.use_notice?(@item) }.to_a
      if to_users.present?

        # deliver_workflow_remand
        url = request.base_url + params[:url]
        comment = params[:remand_comment]

        notifier = Gws::Affair::Notifier.new(@item)
        notifier.deliver_workflow_remand(to_users, url: url, comment: comment)

      end
    end
    render json: { workflow_state: @item.workflow_state }
  end

  def request_cancel
    set_item

    raise "403" unless @item.allowed?(:edit, @cur_user)

    return if request.get? || request.head?

    @item.approved = nil
    # @item.workflow_user_id = nil
    @item.workflow_state = @model::WORKFLOW_STATE_CANCELLED

    @item.skip_history_backup = true if @item.respond_to?(:skip_history_backup)
    render_update @item.save, notice: t('workflow.notice.request_cancelled'), render: :request_cancel
  end

  def seen_update
    set_item

    comment = params[:remand_comment]
    file_ids = params[:workflow_file_ids]

    if !@item.update_current_workflow_circulation_state(@cur_user, "seen", comment: comment, file_ids: file_ids)
      @item.errors.add :base, :unable_to_update_cirulaton_state
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    to_users = [ @item.workflow_user, @item.workflow_agent ].compact - [@cur_user]
    to_users.select! { |user| user.use_notice?(@item) }

    if (comment.present? || file_ids.present?) && to_users.present?

      # deliver_workflow_comment
      url = request.base_url + params[:url]
      notifier = Gws::Affair::Notifier.new(@item)
      notifier.deliver_workflow_comment(to_users, url: url, comment: comment)

    end

    if @item.workflow_current_circulation_completed? && @item.move_workflow_circulation_next_step
      current_circulation_users = @item.workflow_current_circulation_users.nin(id: @cur_user.id).active
      current_circulation_users = current_circulation_users.select { |user| user.use_notice?(@item) }
      if current_circulation_users.present?

        # deliver_workflow_circulations
        url = request.base_url + params[:url]

        notifier = Gws::Affair::Notifier.new(@item)
        notifier.deliver_workflow_circulations(current_circulation_users, url: url, comment: comment)

      end
    end

    if !@item.save
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    render json: { workflow_state: @item.workflow_state }
  end

  def set_week_in_leave_file(item)
    return if !item.respond_to?(:week_in_compensatory_minute)

    leave_file = item.week_in_leave_file
    if item.week_in_start_at.present? && item.week_in_compensatory_minute.to_i > 0
      leave_file ||= Gws::Affair::LeaveFile.new

      leave_file.cur_user = item.user
      leave_file.cur_site = item.site
      leave_file.target_user = item.target_user
      leave_file.target_group = item.target_group
      leave_file.leave_type = "week_in_compensatory_leave"

      leave_file.week_in_compensatory_file = item
      leave_file.week_out_compensatory_file = nil
      leave_file.holiday_compensatory_file = nil

      leave_file.start_at = item.week_in_start_at
      leave_file.start_at_date = item.week_in_start_at_date
      leave_file.start_at_hour = item.week_in_start_at_hour
      leave_file.start_at_minute = item.week_in_start_at_minute

      leave_file.end_at = item.week_in_end_at
      leave_file.end_at_date = item.week_in_end_at_date
      leave_file.end_at_hour = item.week_in_end_at_hour
      leave_file.end_at_minute = item.week_in_end_at_minute

      leave_file.permission_level = item.permission_level
      leave_file.group_ids = item.group_ids
      leave_file.user_ids = item.user_ids
      leave_file.state = item.state
      leave_file.workflow_user_id = item.workflow_user_id
      leave_file.workflow_state = item.workflow_state
      leave_file.workflow_approvers = item.workflow_approvers
      leave_file.workflow_required_counts = item.workflow_required_counts
      leave_file.workflow_circulations = item.workflow_circulations
      leave_file.workflow_current_circulation_level = item.workflow_current_circulation_level
      leave_file.approved = item.approved

      leave_file.save
    elsif leave_file
      leave_file.destroy
    end
  end

  def set_week_out_leave_file(item)
    return if !item.respond_to?(:week_out_compensatory_minute)

    leave_file = item.week_out_leave_file
    if item.week_out_start_at.present? && item.week_out_compensatory_minute.to_i > 0
      leave_file ||= Gws::Affair::LeaveFile.new

      leave_file.cur_user = item.user
      leave_file.cur_site = item.site
      leave_file.target_user = item.target_user
      leave_file.target_group = item.target_group
      leave_file.leave_type = "week_out_compensatory_leave"

      leave_file.week_in_compensatory_file = nil
      leave_file.week_out_compensatory_file = item
      leave_file.holiday_compensatory_file = nil

      leave_file.start_at = item.week_out_start_at
      leave_file.start_at_date = item.week_out_start_at_date
      leave_file.start_at_hour = item.week_out_start_at_hour
      leave_file.start_at_minute = item.week_out_start_at_minute

      leave_file.end_at = item.week_out_end_at
      leave_file.end_at_date = item.week_out_end_at_date
      leave_file.end_at_hour = item.week_out_end_at_hour
      leave_file.end_at_minute = item.week_out_end_at_minute

      leave_file.permission_level = item.permission_level
      leave_file.group_ids = item.group_ids
      leave_file.user_ids = item.user_ids
      leave_file.state = item.state
      leave_file.workflow_user_id = item.workflow_user_id
      leave_file.workflow_state = item.workflow_state
      leave_file.workflow_approvers = item.workflow_approvers
      leave_file.workflow_required_counts = item.workflow_required_counts
      leave_file.workflow_circulations = item.workflow_circulations
      leave_file.workflow_current_circulation_level = item.workflow_current_circulation_level
      leave_file.approved = item.approved

      leave_file.save
    elsif leave_file
      leave_file.destroy
    end
  end

  def set_holiday_leave_file(item)
    return if !item.respond_to?(:holiday_compensatory_minute)

    leave_file = item.holiday_compensatory_leave_file
    if item.holiday_compensatory_start_at.present? && item.holiday_compensatory_minute.to_i > 0
      leave_file ||= Gws::Affair::LeaveFile.new

      leave_file.cur_user = item.user
      leave_file.cur_site = item.site
      leave_file.target_user = item.target_user
      leave_file.target_group = item.target_group
      leave_file.leave_type = "holiday_compensatory_leave"

      leave_file.week_in_compensatory_file = nil
      leave_file.week_out_compensatory_file = nil
      leave_file.holiday_compensatory_file = item

      leave_file.start_at = item.holiday_compensatory_start_at
      leave_file.start_at_date = item.holiday_compensatory_start_at_date
      leave_file.start_at_hour = item.holiday_compensatory_start_at_hour
      leave_file.start_at_minute = item.holiday_compensatory_start_at_minute

      leave_file.end_at = item.holiday_compensatory_end_at
      leave_file.end_at_date = item.holiday_compensatory_end_at_date
      leave_file.end_at_hour = item.holiday_compensatory_end_at_hour
      leave_file.end_at_minute = item.holiday_compensatory_end_at_minute

      leave_file.permission_level = item.permission_level
      leave_file.group_ids = item.group_ids
      leave_file.user_ids = item.user_ids
      leave_file.state = item.state
      leave_file.workflow_user_id = item.workflow_user_id
      leave_file.workflow_state = item.workflow_state
      leave_file.workflow_approvers = item.workflow_approvers
      leave_file.workflow_required_counts = item.workflow_required_counts
      leave_file.workflow_circulations = item.workflow_circulations
      leave_file.workflow_current_circulation_level = item.workflow_current_circulation_level
      leave_file.approved = item.approved

      leave_file.save
    elsif leave_file
      leave_file.destroy
    end
  end
end
