class Opendata::Workflow::IdeaCommentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :set_item, only: [:request_update, :approve_update, :remand_update, :branch_create, :approver_setting]
  before_action :set_route, only: [:approver_setting]

  private
    def set_model
      @model = Opendata::IdeaComment
    end

    def set_item
      @item = @model.find(params[:id])
      @item.attributes = fix_params
    end

    def set_route
      route_id = params[:route_id]
      if "my_group" == route_id
        @route = nil
      else
        @route = Workflow::Route.find(params[:route_id])
      end
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
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

    def group_id
      default_group_id = @cur_user.group_ids.first
      return default_group_id if params[:s].blank?
      return default_group_id if params[:s][:group].blank?

      group_id = params[:s][:group]
      case group_id
      when "false" then
        false
      else
        group_id.to_i
      end
    end

    def group_options
      groups = Cms::Group.site(@cur_site).each.select do |g|
        g.allowed?(:read, @cur_user, site: @cur_site)
      end
      groups.reduce([]) do |ret, g|
        ret << [ g.name, g.id ]
      end.to_a
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
            master.generate_file
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

    def wizard
      render layout: false
    end

    def approver_setting
      if @route.present?
        if @item.apply_workflow?(@route)
          render file: "approver_setting_multi", layout: false
        else
          render json: @item.errors.full_messages, status: :bad_request
        end
      else
        render layout: false
      end
    end
end
