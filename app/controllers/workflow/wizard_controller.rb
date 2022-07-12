class Workflow::WizardController < ApplicationController
  include Cms::ApiFilter
  include Workflow::WizardFilter

  before_action :set_route, only: [:approver_setting]
  before_action :set_item
  before_action :set_routes

  private

  def set_model
    @model = Cms::Page
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
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
      item = @model.site(@cur_site).find(params[:id])
      item.attributes = fix_params
      item
    end
  end

  def set_routes
    @route_options ||= Workflow::Route.site(@cur_site).route_options(@cur_user, item: @item)
  end

  public

  def index
    render template: "index", layout: false
  end

  def approver_setting
    if @route.present?
      if @item.apply_workflow?(@route)
        render template: "approver_setting_multi", layout: false
      else
        render json: @item.errors.full_messages, status: :bad_request
      end
    elsif @route_id == "my_group"
      render template: "approver_setting", layout: false
    elsif @route_id == "restart"
      render template: "approver_setting_restart", layout: false
    else
      raise "404"
    end
  end

  def reroute
    level = Integer(params[:level])

    workflow_approvers = @item.workflow_approvers
    workflow_approvers = workflow_approvers.select do |workflow_approver|
      workflow_approver[:level] == level
    end
    same_level_user_ids = workflow_approvers.map do |workflow_approver|
      workflow_approver[:user_id]
    end

    criteria = @item.approver_user_class.site(@cur_site)
    criteria = criteria.search(params[:s])
    criteria = criteria.nin(id: same_level_user_ids + [ @item.workflow_user_id ])
    criteria = criteria.order_by(filename: 1)

    @items = criteria.select do |user|
      @item.allowed?(:read, user, site: @cur_site) && @item.allowed?(:approve, user, site: @cur_site)
    end
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)

    render template: 'reroute', layout: false
  end
end
