class Gws::Tabular::Frames::ApproversController < ApplicationController
  include Gws::ApiFilter

  before_action :set_frame_id
  before_action :set_workflow_approver_alternate, only: [:update]

  helper_method :ref, :route_options, :use_agent?, :route_id, :route, :find_approver, :find_circulator, :routing_error?
  helper_method :with_approval?, :policy

  layout "ss/item_frame"

  model Gws::Tabular::File

  private

  def set_frame_id
    @frame_id ||= "workflow-approver-frame"
  end

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def forms
    @forms ||= begin
      criteria = Gws::Tabular::Form.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.reorder(order: 1, id: 1)
    end
  end

  def cur_form
    @cur_form ||= begin
      form = forms.find(params[:form])
      form.site = form.cur_site = @cur_site
      form.space = form.cur_space = cur_space
      form
    end
  end

  def cur_release
    @cur_release ||= begin
      release = cur_form.current_release
      raise "404" unless release
      release
    end
  end

  def views
    @views ||= begin
      criteria = Gws::Tabular::View::Base.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.in(form_id: forms.pluck(:id))
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.reorder(order: 1, id: 1)
    end
  end

  def cur_view
    return @cur_view if instance_variable_defined?(:@cur_view)

    view_param = params[:view].to_s.presence
    if view_param == '-'
      @cur_view = Gws::Tabular::View::DefaultView.new(cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space)
    else
      @cur_view = views.find(view_param)
    end
    raise "404" unless @cur_view

    @cur_view.site = @cur_site
    @cur_view.space = cur_space
    @cur_view.form = cur_form
    @cur_view
  end

  def set_model
    @model = Gws::Tabular::File[cur_release]
  end

  def set_item
    super
    if @item
      @item.site = @item.cur_site = @cur_site
      @item.space = @item.cur_space = cur_space
      @item.form = @item.cur_form = cur_form
    end
    @item
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
      ref = params[:ref].to_s.strip
      if ref.present? && !Sys::TrustedUrlValidator.valid_url?(ref)
        ref = nil
      end

      if ref.blank?
        ref = gws_tabular_file_path(space: cur_space, form: cur_form, view: cur_view, id: @item)
      end

      ref
    end
  end

  def route_options
    @route_options ||= Gws::Workflow2::Route.route_options(@cur_user, cur_site: @cur_site, item: @item)
  end

  def use_agent?
    return false unless @item.agent_enabled?
    # @cur_user.gws_role_permit_any?(@cur_site, :agent_all_gws_workflow_files, :agent_private_gws_workflow_files)
    true
  end

  def default_route_id
    return "restart" if @item.workflow_state == "cancelled"

    cur_form.try(:default_route_id).presence
  end

  def route_id
    return @route_id if @route_id

    if params.key?(:item)
      route_id = params.expect(item: [:route_id])[:route_id]
    end
    route_id = default_route_id if route_id.blank?
    route_id = "my_group" if route_id.blank?

    if BSON::ObjectId.legal?(route_id)
      # 申請フォームにセットされている既定の route が削除されているかもしれない
      # route が削除されている場合、@route_id に "my_group" をセットする
      @route = Gws::Workflow2::Route.site(@cur_site).find(route_id) rescue nil
      @route_id = @route ? route_id : "my_group"
    elsif route_id.numeric?
      raise "Gws::Workflow::Route is not supported"
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

  def find_approver(user_id)
    @id_approver_map ||= begin
      user_ids = @item.workflow_approvers.map { |approver| approver[:user_id] }
      user_ids += @item.workflow_circulations.map { |circulation| circulation[:user_id] }
      user_ids.uniq!
      user_ids.compact!

      Gws::User.all.site(@cur_site).active.only(:id, :i18n_name, :uid, :email).in(id: user_ids).to_a.index_by(&:id)
    end

    @id_approver_map[user_id]
  end
  alias find_circulator find_approver

  def interpret_route
    resolver = Gws::Workflow2::ApproverResolver.new(
      cur_site: @cur_site, cur_user: @cur_user, cur_group: @cur_group, route: route || route_id.to_sym, item: @item)
    if params.key?(:item)
      resolver.attributes = params.require(:item).permit(*Gws::Workflow2::ApproverResolver::PERMIT_PARAMS)
    end
    resolver.resolve
  end

  def routing_error?
    return true if @item.workflow_approvers.any? { |approver| approver[:error].present? }
    return true if @item.workflow_circulations.any? { |circulation| circulation[:error].present? }
    false
  end

  def with_approval?
    cur_form.try(:approval_state_with_approval?)
  end

  def policy
    @policy ||= Gws::Tabular::Frames::ApproversPolicy.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, model: @model, item: @item)
  end

  # rubocop:disable Rails/ActionControllerFlashBeforeRender
  def _update
    interpret_route if with_approval?

    if params.key?(:route)
      render template: "edit", status: :ok
      return
    end

    @item.destination_group_ids = cur_form.destination_group_ids
    @item.destination_user_ids = cur_form.destination_user_ids
    if @item.destination_groups.active.present? || @item.destination_users.active.present?
      @item.destination_treat_state = "untreated"
    else
      @item.destination_treat_state = "no_need_to_treat"
    end

    if with_approval?
      service_class = Gws::Workflow2::RequestService
    else
      service_class = Gws::Tabular::RequestWithoutApprovalService
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
  # rubocop:enable Rails/ActionControllerFlashBeforeRender

  public

  def show
    unless policy.show?
      render plain: t("errors.messages.auth_error"), status: :forbidden
      return
    end

    template = policy.show_template
    interpret_route if template == "edit" && with_approval?
    render template: template
  end

  def update
    unless policy.update?
      @item.errors.add :base, :auth_error
      render template: "edit", status: :forbidden
      return
    end

    _update
  end

  def restart
    set_item
    unless policy.restart?
      @item.errors.add :base, :auth_error
      render template: "edit", status: :forbidden
      return
    end

    _update
  end

  # rubocop:disable Rails/ActionControllerFlashBeforeRender
  def cancel
    set_item
    unless policy.cancel?
      @item.errors.add :base, :auth_error
      render template: "show", status: :forbidden
      return
    end

    service = Gws::Workflow2::CancelService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item, ref: ref)
    unless service.call
      SS::Model.copy_errors(service, @item)
      render template: "show", status: :unprocessable_entity
      return
    end

    flash[:notice] = t("workflow.notice.request_cancelled")
    json = { status: 302, location: ref }
    render json: json, status: :ok, content_type: json_content_type
  end
  # rubocop:enable Rails/ActionControllerFlashBeforeRender
end
