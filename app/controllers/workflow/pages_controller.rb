class Workflow::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :set_item, only: [:request_update, :approve_update, :remand_update, :branch_create]

  private
    def set_model
      @model = Cms::Page
    end

    def set_item
      @item = @model.find(params[:id]).becomes_with_route
      @item.attributes = fix_params
      @item.try(:allow_other_user_files)
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

    def request_approval
      current_level = @item.workflow_current_level
      current_workflow_approvers = @item.workflow_approvers_at(current_level)
      current_workflow_approvers.each do |workflow_approver|
        args = { f_uid: @cur_user._id, t_uid: workflow_approver[:user_id],
                 site: @cur_site, page: @item,
                 url: params[:url], comment: params[:workflow_comment] }
        Workflow::Mailer.request_mail(args).deliver_now if mail_enabled?(args[:t_uid])
      end

      @item.set_workflow_approver_state_to_request
      @item.update
    end

    def mail_enabled?(target_id)
      target_user = SS::User.find(target_id) rescue false
      target_user_email = target_user.email if target_user.present?
      @cur_user.email.present? && target_user_email.present?
    end

    def email_blank_ids
      email_blank_id = []
      email_blank_id.push(@cur_user._id) if @cur_user.email.blank?
      if @item.workflow_state == "request"
        current_level = @item.workflow_current_level
        current_workflow_approvers = @item.workflow_approvers_at(current_level)
        current_workflow_approvers.each do |workflow_approver|
          if @cur_user._id !=workflow_approver[:user_id]
            approver_user = SS::User.where(id: workflow_approver[:user_id]).first
            if approver_user
              approver_user_email = approver_user.email
              email_blank_id.push(approver_user._id) if approver_user_email.blank?
            end
          end
        end
      else
        applicant_user = SS::User.where(id: @item.workflow_user_id).first
        if applicant_user
          applicant_user_email = applicant_user.email
          email_blank_id.push(applicant_user._id) if applicant_user_email.blank?
        end
      end
      email_blank_id
    end

    def workflow_alert_message
      ids = email_blank_ids
      return if ids.blank?
      message = t("errors.messages.user_email_blank")
      ids.each do |id|
        user = SS::User.where(id: id).first
        message += "\n#{user.name}"
      end
      message
    end

  public
    def request_update
      raise "403" unless @item.allowed?(:edit, @cur_user)

      @item.workflow_user_id = @cur_user._id
      @item.workflow_state   = "request"
      @item.workflow_comment = params[:workflow_comment]
      @item.workflow_approvers = params[:workflow_approvers]
      @item.workflow_required_counts = params[:workflow_required_counts]

      if @item.update
        request_approval
        render json: { workflow_state: @item.workflow_state, workflow_alert: workflow_alert_message }
      else
        render json: @item.errors.full_messages, status: :unprocessable_entity
      end

    end

    def approve_update
      raise "403" unless @item.allowed?(:approve, @cur_user)

      save_level = @item.workflow_current_level
      @item.update_current_workflow_approver_state(@cur_user, @model::WORKFLOW_STATE_APPROVE, params[:remand_comment])

      if @item.finish_workflow?
        @item.workflow_state = @model::WORKFLOW_STATE_APPROVE
        @item.state = "public"

        if @item.respond_to?(:release_date)
          if @item.release_date
            @item.state = "ready"
          else
            @item.release_date = nil
          end
        end
      end

      if @item.update
        current_level = @item.workflow_current_level
        if save_level != current_level
          # escalate workflow
          request_approval
        end

        workflow_state = @item.workflow_state
        if workflow_state == @model::WORKFLOW_STATE_APPROVE
          @item.workflow_state = workflow_state
          # finished workflow
          args = { f_uid: @cur_user._id, t_uid: @item.workflow_user_id,
                   site: @cur_site, page: @item,
                   url: params[:url], comment: params[:remand_comment] }
          Workflow::Mailer.approve_mail(args).deliver_now if mail_enabled?(args[:t_uid])

          if @item.try(:branch?) && @item.state == "public"
            @item.delete
          end
        end

        render json: { workflow_state: @item.workflow_state, workflow_alert: workflow_alert_message }
      else
        render json: @item.errors.full_messages, status: :unprocessable_entity
      end
    end

    def remand_update
      raise "403" unless @item.allowed?(:approve, @cur_user)

      @item.workflow_state = @model::WORKFLOW_STATE_REMAND
      @item.update_current_workflow_approver_state(@cur_user, @model::WORKFLOW_STATE_REMAND, params[:remand_comment])

      if @item.update
        if @item.workflow_state == "remand"
          args = { f_uid: @cur_user._id, t_uid: @item.workflow_user_id,
                   site: @cur_site, page: @item,
                   url: params[:url], comment: params[:remand_comment] }
          Workflow::Mailer.remand_mail(args).deliver_now if mail_enabled?(args[:t_uid])
        end
        render json: { workflow_state: @item.workflow_state, workflow_alert: workflow_alert_message }
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
