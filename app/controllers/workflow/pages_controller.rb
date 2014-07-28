# coding: utf-8
class Workflow::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :set_item, only: [:request_update, :approve_update, :remand_update]

  private
    def render(*args)
      {}
    end

    def set_model
       @model = params[:cid]? Article::Page : Cms::Page
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

  public
    def request_update
      raise "403" unless @item.allowed?(:edit, @cur_user)
      @item.workflow_user_id = @cur_user._id
      @item.workflow_state = "request"
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
      sel = ""
      stfg = 1
      @item.workflow_approvers.split(/\r\n|\n/).each do |d|
        col = d.split(",")
        if col[1].to_i == @cur_user._id
           col[2] = "approve"
           col[3] = params[:remand_comment].gsub(/\n|\r\n/, " ")
        end
        sel << col.join(",") + "\r\n"
        stfg = 0 if col[2] != "approve"
      end
      @item.workflow_approvers = sel
      if stfg == 1
        @item.workflow_state = "approve"
        @item.state = "public"
        @item.release_date = nil
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
      sel = ""
      @item.workflow_approvers.split(/\r\n|\n/).each do |d|
        col = d.split(",")
        if col[1].to_i == @cur_user._id
           col[2] = "remand"
           col[3] = params[:remand_comment].gsub(/\n|\r\n/, " ")
        end
        sel << col.join(",") + "\r\n"
      end
      @item.workflow_approvers = sel
      @item.workflow_state = "remand"
      if @item.update && @item.workflow_state == "remand"
        args = { f_uid: @cur_user._id, t_uid: @item.workflow_user_id,
                 site: @cur_site, page: @item,
                 url: params[:url], comment: params[:remand_comment] }
        Workflow::Mailer.remand_mail(args).deliver
      end
    end
end
