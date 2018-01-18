class Gws::Workflow::WizardController < ApplicationController
  include Gws::ApiFilter
  include Workflow::WizardFilter

  prepend_view_path "app/views/workflow/wizard"

  before_action :set_route, only: [:approver_setting]
  before_action :set_item, only: [:approver_setting, :reroute, :do_reroute]

  private

  def set_model
    @model = Gws::Workflow::File
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_route
    route_id = params[:route_id]
    if "my_group" == route_id
      @route = nil
    else
      @route = Gws::Workflow::Route.find(params[:route_id])
    end
  end

  def set_item
    @item = @model.find(params[:id]) #.becomes_with_route
    @item.attributes = fix_params
  end

  public

  def index
    render file: :index, layout: false
  end

  def approver_setting
    @item.workflow_user_id = nil
    @item.workflow_state = nil
    @item.workflow_comment = nil
    @item.workflow_approvers = nil
    @item.workflow_required_counts = nil

    if @route.present?
      if @item.apply_workflow?(@route)
        render file: "approver_setting_multi", layout: false
      else
        render json: @item.errors.full_messages, status: :bad_request
      end
    else
      render file: :approver_setting, layout: false
    end
  end

  def reroute
    if params.dig(:s, :group).present?
      @group = @cur_site.descendants.active.find(params.dig(:s, :group)) rescue nil
      @group ||= @cur_site
    else
      @group = @cur_user.groups.active.in_group(@cur_site).first
    end

    @cur_user = @item.approver_user_class.site(@cur_site).active.find(params[:user_id]) rescue nil

    level = Integer(params[:level])

    workflow_approvers = @item.workflow_approvers
    workflow_approvers = workflow_approvers.select do |workflow_approver|
      workflow_approver[:level] == level
    end
    same_level_user_ids = workflow_approvers.map do |workflow_approver|
      workflow_approver[:user_id]
    end

    group_ids = @cur_site.descendants.active.in_group(@group).pluck(:id)
    criteria = @item.approver_user_class.site(@cur_site)
    criteria = criteria.active
    criteria = criteria.in(group_ids: group_ids)
    criteria = criteria.nin(id: same_level_user_ids + [ @item.workflow_user_id ])
    criteria = criteria.search(params[:s])
    criteria = criteria.order_by_title(@cur_site)

    @items = criteria.select do |user|
      @item.allowed?(:read, user, site: @cur_site) && @item.allowed?(:approve, user, site: @cur_site)
    end
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)

    render file: 'reroute', layout: false
  end
end
