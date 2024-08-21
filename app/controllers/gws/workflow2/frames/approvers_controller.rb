class Gws::Workflow2::Frames::ApproversController < ApplicationController
  include Gws::ApiFilter

  before_action :set_frame_id
  before_action :set_workflow_approver_alternate, only: [:update]

  helper_method :ref, :route_options, :use_agent?, :route_id, :route, :find_approver, :find_circulator, :routing_error?
  helper_method :with_approval?

  layout "ss/item_frame"

  model Gws::Workflow2::File

  private

  def set_frame_id
    @frame_id = "workflow-approver-frame"
  end

  def set_workflow_approver_alternate
    return unless @item.route_my_group_alternate?
    return if params[:item][:workflow_approver_alternate]

    # default value
    if alternate = @item.workflow_approvers[1]
      @item.workflow_approvers = [@item.workflow_approvers[0]]
      @item.workflow_approver_alternate = [alternate[:user_id]]
      @workflow_approver_alternate = Gws::User.site(@cur_site).find(alternate[:user_id]) rescue nil
    end
  end

  def ref
    @ref ||= begin
      ref = params[:ref].to_s.presence
      if ref && !Sys::TrustedUrlValidator.valid_url?(ref)
        ref = nil
      end

      ref.presence || gws_workflow2_file_path(state: 'all', id: @item)
    end
  end

  def route_options
    @route_options ||= Gws::Workflow2::Route.route_options(@cur_user, cur_site: @cur_site, item: @item)
  end

  def use_agent?
    return false unless @item.agent_enabled?
    @cur_user.gws_role_permit_any?(@cur_site, :agent_all_gws_workflow_files, :agent_private_gws_workflow_files)
  end

  def default_route_id
    return "restart" if @item.workflow_state == "cancelled"
    @item.form.try(:default_route_id).presence
  end

  def route_id
    return @route_id if @route_id

    if params.key?(:item)
      route_id = params.require(:item).permit(:route_id)[:route_id]
    end
    route_id = default_route_id if route_id.blank?
    route_id = "my_group" if route_id.blank?

    if BSON::ObjectId.legal?(route_id)
      # 申請フォームにセットされている既定の route が削除されているかもしれない
      # route が削除されている場合、@route_id に "my_group" をセットする
      @route = Gws::Workflow2::Route.site(@cur_site).find(route_id) rescue nil
      @route_id = @route ? route_id : "my_group"
    else
      @route_id = route_id
      @route = nil
    end

    @route_id
  end

  def route
    return @route if instance_variable_defined?(:@route)

    route_id
    @route
  end

  def show_template
    if @item.try(:cloned_name?) && @item.readable?(@cur_user, site: @cur_site)
      "cloned_name"
    elsif @item.workflow_state.blank? && @item.editable?(@cur_user, site: @cur_site)
      "edit"
    elsif @item.readable?(@cur_user, site: @cur_site)
      "show"
    end
  end

  def find_approver(user_id)
    @id_approver_map ||= begin
      # rubocop:disable Rails/Pluck
      user_ids = @item.workflow_approvers.map { |approver| approver[:user_id] }
      user_ids += @item.workflow_circulations.map { |circulation| circulation[:user_id] }
      # rubocop:enable Rails/Pluck
      user_ids.uniq!
      user_ids.compact!

      Gws::User.all.site(@cur_site).active.only(:id, :name, :uid, :email).in(id: user_ids).to_a.index_by(&:id)
    end

    @id_approver_map[user_id]
  end
  alias find_circulator find_approver

  def interpret_route
    resolver = Gws::Workflow2::ApproverResolver.new(
      cur_site: @cur_site, cur_user: @cur_user, cur_group: @cur_group, route: route || route_id.to_sym, item: @item)
    resolver.resolve
  end

  def routing_error?
    return true if @item.workflow_approvers.any? { |approver| approver[:error].present? }
    return true if @item.workflow_circulations.any? { |circulation| circulation[:error].present? }
    false
  end

  def with_approval?
    @item.form.try(:approval_state_with_approval?)
  end

  public

  def show
    template = show_template
    if template
      interpret_route if template == "edit" && with_approval?
      render template: template
      return
    end

    render plain: t("errors.messages.auth_error"), status: :forbidden
  end

  def update
    unless @item.allowed?(:edit, @cur_user, site: @cur_site, adds_error: false)
      @item.errors.add :base, :auth_error
      render template: "edit", status: :forbidden
      return
    end

    interpret_route if with_approval?

    if params.key?(:route)
      render template: "edit", status: :ok
      return
    end

    if with_approval?
      service_class = Gws::Workflow2::RequestService
    else
      service_class = Gws::Workflow2::RequestWithoutApprovalService
    end
    service = service_class.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, route_id: route_id, route: route,
      item: @item, ref: ref)
    if params.key?(:item)
      service.attributes = params.require(:item).permit(*service_class::PERMIT_PARAMS)
    end
    unless service.call
      @item.workflow_state = nil
      render template: "edit", status: :unprocessable_entity
      return
    end

    flash[:notice] = t("gws/workflow2.notice.requested")
    json = { status: 302, location: ref }
    render json: json, status: :ok, content_type: json_content_type
  end

  def cancel
    set_item

    if @item.workflow_user_id != @cur_user.id && @item.workflow_agent_id != @cur_user.id
      @item.errors.add :base, :auth_error
      render template: "show", status: :forbidden
      return
    end

    service = Gws::Workflow2::CancelService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item, ref: ref)
    unless service.call
      render template: "show", status: :unprocessable_entity
      return
    end

    flash[:notice] = t("workflow.notice.request_cancelled")
    json = { status: 302, location: ref }
    render json: json, status: :ok, content_type: json_content_type
  end

  def reroute
    set_item
    unless @item.allowed?(:reroute, @cur_user, site: @cur_site, adds_error: false)
      @item.errors.add :base, :auth_error
      render template: "edit", status: :forbidden
      return
    end

    service = Gws::Workflow2::RerouteService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item, ref: ref)
    service.attributes = params.require(:item).permit(*Gws::Workflow2::RerouteService::PERMIT_PARAMS)
    unless service.call
      render template: "edit", status: :unprocessable_entity
      return
    end

    flash[:notice] = t("gws/workflow2.notice.rerouted")
    json = { status: 302, location: ref }
    render json: json, status: :ok, content_type: json_content_type
  end
end
