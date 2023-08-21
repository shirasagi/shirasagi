class Cms::Apis::Preview::Workflow::WizardController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  layout "ss/ajax_in_iframe"

  before_action :set_route, only: [:approver_setting]
  before_action :set_item
  before_action :check_item_status
  before_action :check_item_lock_status
  before_action :set_routes

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_route
    @route_id = params[:route_id]
    if @route_id == "my_group" || @route_id == "restart"
      @route = nil
    else
      @route = Workflow::Route.site(@cur_site).find(params[:route_id])
    end
  end

  def set_item
    @item ||= begin
      item = @cur_page = Cms::Page.site(@cur_site).find(params[:id])
      item.attributes = fix_params
      @model = item.class
      item
    end
  end

  def check_item_status
    # 非公開状態でないと、承認に関するあらゆる操作はできない
    raise "404" if @item.state != "closed"
  end

  def check_item_lock_status
    return if !@item.respond_to?(:locked?)
    return if !@item.respond_to?(:lock_owned?)

    if @item.locked? && !@item.lock_owned?
      render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked
      return
    end
  end

  def set_routes
    @route_options ||= Workflow::Route.site(@cur_site).route_options(@cur_user, item: @item, site: @cur_site)
  end

  public

  def index
    if @route_options.length == 1
      _route_name, route_id = @route_options.first
      redirect_to url_for(action: "approver_setting", route_id: route_id)
      return
    end

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
        render template: "approver_setting_multi", locals: { cancel_button: @route_options.count > 1 }, layout: false
      else
        render json: @item.errors.full_messages, status: :bad_request
      end
    elsif @route_id == "my_group"
      render template: "approver_setting", locals: { cancel_button: @route_options.count > 1 }, layout: false
    elsif @route_id == "restart"
      render template: "approver_setting_restart", layout: false
    else
      raise "404"
    end
  end
end
