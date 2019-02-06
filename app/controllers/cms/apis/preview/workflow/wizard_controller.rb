class Cms::Apis::Preview::Workflow::WizardController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  layout "ss/ajax_in_iframe"

  before_action :set_route, only: [:approver_setting]
  before_action :set_item
  before_action :check_item_status

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_route
    @route_id = params[:route_id]
    if @route_id == "my_group" || @route_id == "restart"
      @route = nil
    else
      @route = Workflow::Route.find(params[:route_id])
    end
  end

  def set_item
    @item = @cur_page = Cms::Page.site(@cur_site).find(params[:id]).becomes_with_route
    @item.attributes = fix_params

    @model = @item.class
  end

  def check_item_status
    # 非公開状態でないと、承認に関するあらゆる操作はできない
    raise "404" if @item.state != "closed"
  end

  public

  def index
    render layout: false
  end

  def frame
    render layout: false
  end

  def comment
    render layout: false
  end

  def approver_setting
    if @route.present?
      if @item.apply_workflow?(@route)
        render file: "approver_setting_multi", layout: false
      else
        render json: @item.errors.full_messages, status: :bad_request
      end
    elsif @route_id == "my_group"
      render file: :approver_setting, layout: false
    elsif @route_id == "restart"
      render file: "approver_setting_restart", layout: false
    else
      raise "404"
    end
  end
end
