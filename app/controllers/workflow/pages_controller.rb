class Workflow::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :set_item, only: [:request_update, :approve_update, :remand_update]

  private
    def render(*args)
      {}
    end

    def set_model
       @model = Cms::Page
    end

    def set_item
      @item = @model.find(params[:id]).becomes_with_route
      @item.attributes = fix_params
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

    def set_userstate(state)
      ret = { approve_flg: 1, workflow_approvers: "" }

      @item.workflow_approvers.split(/\r\n|\n/).each do |d|
        col = d.split(",")
        if col[1].to_i == @cur_user._id
           col[2] = state
           col[3] = params[:remand_comment].gsub(/\n|\r\n/, " ")
        end
        ret[:workflow_approvers] << col.join(",") + "\r\n"
        ret[:approve_flg] = 0 if col[2] != "approve"
      end
      ret
    end

  public
    def request_update
      raise "403" unless @item.allowed?(:edit, @cur_user)

      @item.workflow_user_id = @cur_user._id
      @item.workflow_state   = "request"
      @item.workflow_comment = params[:workflow_comment]

      sel = ""
      params[:workflow_approvers].each do |d|
        sel << "1,#{d},request,\r\n"
      end
      @item.workflow_approvers = sel

      if @item.update
        params[:workflow_approvers].each do |d|
          args = { f_uid: @cur_user._id, t_uid: d,
                   site: @cur_site, page: @item,
                   url: params[:url], comment: params[:workflow_comment] }
          Workflow::Mailer.request_mail(args).deliver
        end
      end
    end

    def approve_update
      raise "403" unless @item.allowed?(:approve, @cur_user)

      updinf = set_userstate("approve")
      @item.workflow_approvers = updinf[:workflow_approvers]

      if updinf[:approve_flg] == 1
        @item.workflow_state = "approve"
        if @item.release_date
          @item.state = "ready"
        else
          @item.state = "public"
          @item.release_date = nil
        end
      end

      if @item.update && @item.workflow_state == "approve"
        args = { f_uid: @cur_user._id, t_uid: @item.workflow_user_id,
                 site: @cur_site, page: @item,
                 url: params[:url], comment: params[:remand_comment] }
        Workflow::Mailer.approve_mail(args).deliver
      end
    end

    def remand_update
      raise "403" unless @item.allowed?(:approve, @cur_user)

      updinf = set_userstate("remand")
      @item.workflow_approvers = updinf[:workflow_approvers]
      @item.workflow_state = "remand"

      if @item.update && @item.workflow_state == "remand"
        args = { f_uid: @cur_user._id, t_uid: @item.workflow_user_id,
                 site: @cur_site, page: @item,
                 url: params[:url], comment: params[:remand_comment] }
        Workflow::Mailer.remand_mail(args).deliver
      end
    end
end
