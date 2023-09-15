module Gws::Workflow::WizardFilter
  extend ActiveSupport::Concern
  include Workflow::WizardFilter

  included do
    prepend_view_path "app/views/workflow/wizard"

    before_action :set_route, only: [:approver_setting]
    before_action :set_item
    before_action :set_routes
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_route
    @route_id = params[:route_id]
    if @route_id == "my_group" || @route_id == "restart"
      @route = nil
    else
      @route = Gws::Workflow::Route.find(params[:route_id])
    end
  end

  def set_item
    @item ||= begin
      item = @model.find(params[:id])
      item.attributes = fix_params
      item
    end
  end

  def set_routes
    @route_options = Gws::Workflow::Route.route_options(@cur_user, item: @item)
  end

  public

  def index
    render template: "index", layout: false
  end

  def approver_setting
    @item.workflow_user_id = nil
    @item.workflow_state = nil
    @item.workflow_comment = nil
    if @route_id != "restart"
      @item.workflow_approvers = nil
      @item.workflow_required_counts = nil
    end

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
    if params.dig(:s, :group).present?
      @group = @cur_site.descendants.active.find(params.dig(:s, :group)) rescue nil
      @group ||= @cur_site
    else
      @group = @cur_user.groups.active.in_group(@cur_site).first
    end

    @cur_user = @item.approver_user_class.site(@cur_site).active.find(params[:user_id]) rescue nil

    level = Integer(params[:level])

    workflow_approvers = @item.workflow_approvers.select { |item| item[:level] == level }
    same_level_user_ids = workflow_approvers.to_a.pluck(:user_id)

    group_ids = @cur_site.descendants_and_self.active.in_group(@group).pluck(:id)
    criteria = @item.approver_user_class.site(@cur_site)
    criteria = criteria.active
    criteria = criteria.in(group_ids: group_ids)
    criteria = criteria.nin(id: same_level_user_ids + [ @item.workflow_user_id, @item.workflow_agent_id ].compact)
    criteria = criteria.search(params[:s])
    criteria = criteria.order_by_title(@cur_site)

    @items = criteria.select do |user|
      @item.allowed?(:read, user, site: @cur_site) && @item.allowed?(:approve, user, site: @cur_site)
    end
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)

    render template: 'reroute', layout: false
  end
end
