class Gws::Tabular::Frames::InspectionsController < ApplicationController
  include Gws::ApiFilter

  layout "ss/item_frame"
  model Gws::Tabular::File

  before_action :set_frame_id
  # before_action :check_approvable

  helper_method :ref, :policy

  private

  def set_frame_id
    @frame_id = "workflow-inspection-frame"
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

  def policy
    @policy ||= Gws::Tabular::Frames::InspectionsPolicy.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, model: @model, item: @item)
  end

  public

  def edit
    unless policy.edit?
      @item.errors.add :base, :auth_error
      render template: "edit", status: :forbidden
      return
    end

    render
  end

  # rubocop:disable Rails/ActionControllerFlashBeforeRender
  def update
    # 詳細なエラーを返したいので、ポリシーによるチェックはしない
    # => 代わりに gws/workflow/approvable_validator で同様のチェックを実施する。
    # unless policy.update?
    #   @item.errors.add :base, :auth_error
    #   render template: "edit", status: :forbidden
    #   return
    # end

    if params.key?(:approve)
      service_class = Gws::Tabular::ApproveService
      notice = t("gws/workflow2.notice.approved")
    elsif params.key?(:pull_up)
      service_class = Gws::Workflow2::PullUpService
      notice = t("gws/workflow2.notice.pulled_up")
    elsif params.key?(:remand)
      service_class = Gws::Workflow2::RemandService
      notice = t("gws/workflow2.notice.remanded")
    end

    service = service_class.new(cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item, ref: ref)
    service.attributes = params.require(:item).permit(*service_class::PERMIT_PARAMS)
    unless service.valid?
      SS::Model.copy_errors(service, @item)
      render_update false
      return
    end
    unless service.call
      SS::Model.copy_errors(service, @item)
      render_update false
      return
    end

    flash[:notice] = notice
    render json: { status: 302, location: ref, notice: notice }, status: :ok, content_type: json_content_type
  end
  # rubocop:enable Rails/ActionControllerFlashBeforeRender

  # rubocop:disable Rails/ActionControllerFlashBeforeRender
  def reroute
    set_item
    unless policy.reroute_myself?
      @item.errors.add :base, :auth_error
      render template: "edit", status: :forbidden
      return
    end

    service = Gws::Workflow2::RerouteService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item, ref: ref)
    service.attributes = params.require(:item).permit(*Gws::Workflow2::RerouteService::PERMIT_PARAMS)
    unless service.call
      SS::Model.copy_errors(service, @item)
      render template: "edit", status: :unprocessable_content
      return
    end

    flash[:notice] = t("gws/workflow2.notice.rerouted")
    json = { status: 302, location: ref }
    render json: json, status: :ok, content_type: json_content_type
  end
  # rubocop:enable Rails/ActionControllerFlashBeforeRender
end
