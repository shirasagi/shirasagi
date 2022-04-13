module Gws::Affair::WizardFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/workflow/wizard"

    before_action :set_route, only: [:approver_setting]
    before_action :set_item
    before_action :set_routes
  end

  private

  def set_item
    @item = @model.find(params[:id])
    @item.attributes = fix_params
  end

  def set_route
    @route_id = params[:route_id]
    if @route_id == "my_group" || @route_id == "restart"
      @route = nil
    else
      @route = Gws::Workflow::Route.find(params[:route_id])
    end
  end

  def validate_domain(user_id)
    return true unless @cur_site.respond_to?(:email_domain_allowed?)
    email = SS::User.find(user_id).email
    @cur_site.email_domain_allowed?(email)
  end

  def set_routes
    @route_options = Gws::Workflow::Route.route_options(@cur_user, item: @item)
  end

  public

  def index
    render template: :index, layout: false
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
      render template: :approver_setting, layout: false
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

    workflow_approvers = @item.workflow_approvers
    workflow_approvers = workflow_approvers.select do |workflow_approver|
      workflow_approver[:level] == level
    end
    same_level_user_ids = workflow_approvers.pluck(:user_id)

    group_ids = @cur_site.descendants.active.in_group(@group).pluck(:id)
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

  def do_reroute
    level = Integer(params[:level])
    user_id = Integer(params[:user_id])
    new_user_id = Integer(params[:new_user_id])

    workflow_approvers = @item.workflow_approvers.to_a.dup
    workflow_approver = workflow_approvers.find do |workflow_approver|
      workflow_approver[:level] == level && workflow_approver[:user_id] == user_id
    end

    if !workflow_approver
      render json: [ I18n.t('errors.messages.no_approvers') ], status: :bad_request
      return
    end

    workflow_approver[:user_id] = new_user_id
    if workflow_approver[:state] != 'request' && workflow_approver[:state] != 'pending'
      workflow_approver[:state] = 'request'
    end
    workflow_approver[:comment] = ''

    @item.workflow_approvers = workflow_approvers
    @item.save!

    #if workflow_approver[:state] == 'request' && validate_domain(new_user_id)
    #  args = {
    #    f_uid: @item.workflow_user_id, t_uid: new_user_id, site: @cur_site, page: @item,
    #    url: params[:url], comment: @item.workflow_comment
    #  }
    #
    #  Workflow::Mailer.request_mail(args).deliver_now
    #end

    render json: { id: @item.id }, status: :ok
  rescue Mongoid::Errors::Validations
    render json: @item.errors.full_messages, status: :bad_request
  rescue => e
    render json: [ e.message ], status: :bad_request
  end

  def approve_by_delegatee
    @level = Integer(params[:level])
    @delegator = @item.class.approver_user_class.site(@cur_site).active.find(params[:delegator_id]) rescue nil

    render template: 'approve_by_delegatee', layout: false
  end
end
