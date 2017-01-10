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
        Workflow::Mailer.request_mail(args).deliver_now
      end

      @item.set_workflow_approver_state_to_request
      @item.update
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
        render json: { workflow_state: @item.workflow_state }
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
          # finished workflow
          args = { f_uid: @cur_user._id, t_uid: @item.workflow_user_id,
                   site: @cur_site, page: @item,
                   url: params[:url], comment: params[:remand_comment] }
          Workflow::Mailer.approve_mail(args).deliver_now if args[:t_uid]

          if @item.try(:branch?) && @item.state == "public"
            master = @item.master
            @item.delete
            master.remove_file
          end
        end

        render json: { workflow_state: workflow_state }
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
          Workflow::Mailer.remand_mail(args).deliver_now if args[:t_uid]
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
