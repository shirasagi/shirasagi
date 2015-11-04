class Opendata::Agents::Nodes::Mypage::App::MyAppController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  helper Opendata::FormHelper
  helper Opendata::UrlHelper
  helper Opendata::ListHelper

  before_action :set_model
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_workflow
  after_action :deliver_workflow_mail, only: [:create, :update]

  protected
    def app_node
      @app_node ||= Opendata::Node::App.site(@cur_site).public.first
    end

    def set_model
      @model = Opendata::App
    end

    def set_item
      @item = @model.site(@cur_site).member(@cur_member).find params[:id]
      @item.attributes = fix_params
    end

    def set_workflow
      @cur_site = Cms::Site.find(@cur_site.id)
      @route = @cur_site.app_workflow_route
    end

    def set_status
      @item.workflow_member_id = @cur_member.id
      @item.cur_site = @cur_site
      status_was = @item.status

      status = "closed"
      status = "request" if @route && params[:request].present?
      status = "public"  if !@route && params[:publish_save].present?
      @item.apply_status(status, member: @cur_member, route: @route, workflow_reset: true)
      @deliver_mail = true if status == "request" && status_was != "request"
    end

    def deliver_workflow_mail
      return unless @route
      return unless @deliver_mail
      return unless @item.errors.empty?
      args = {
        m_id: @cur_member.id,
        t_uid: @item.workflow_approvers.first[:user_id],
        site: @cur_site,
        item: @item,
        url: ::File.join(@cur_site.full_url, opendata_app_path(cid: @cur_node.id, site: @cur_site.host, id: @item.id))
      }
      Opendata::Mailer.request_resource_mail(args).deliver_now rescue nil
    end

    def fix_params
      { site_id: @cur_site.id, member_id: @cur_member.id, cur_node: app_node }
    end

    def pre_params
      {}
    end

    def permit_fields
      @model.permitted_fields
    end

    def get_params
      params.require(:item).permit(permit_fields).merge(fix_params)
    end

  public
    def index
      @items = Opendata::App.site(@cur_site).member(@cur_member).
        order_by(updated: -1).
        page(params[:page]).
        per(20)

      render
    end

    def show
      render
    end

    def new
      @item = @model.new
      render
    end

    def create
      @item = @model.new get_params
      set_status

      if @item.save
        redirect_to @cur_node.url, notice: t("views.notice.saved")
      else
        render action: :new
      end
    end

    def edit
      render
    end

    def update
      @item.attributes = get_params
      set_status

      if @item.update
        redirect_to "#{@cur_node.url}#{@item.id}/", notice: t("views.notice.saved")
      else
        render action: :edit
      end
    end

    def delete
      render
    end

    def destroy
      if @item.destroy
        redirect_to @cur_node.url, notice: t("views.notice.deleted")
      else
        render action: :delete
      end
    end
end
