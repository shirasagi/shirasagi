class Gws::Tabular::Frames::CirculationsController < ApplicationController
  include Gws::ApiFilter

  layout "ss/item_frame"
  model Gws::Tabular::File

  before_action :set_frame_id
  before_action :check_commentable

  helper_method :ref, :workflow_circulation

  private

  def set_frame_id
    @frame_id = "workflow-circulation-frame"
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

  def check_commentable
    if !@item.allowed?(:read, @cur_user, site: @cur_site) || @item.workflow_state != "approve"
      head :not_found
      return
    end

    current_circulation = workflow_circulation
    if current_circulation.blank?
      head :not_found
    end
  end

  def workflow_circulation
    return @workflow_circulation if instance_variable_defined?(:@workflow_circulation)

    @workflow_circulation ||= begin
      workflow_circulations = @item.workflow_circulations
      if workflow_circulations.present?
        workflow_circulations.find do |circulation|
          circulation[:user_id] == @cur_user.id && circulation[:state] == 'unseen'
        end
      end
    end
  end

  public

  # rubocop:disable Rails/ActionControllerFlashBeforeRender
  def update
    service = Gws::Workflow::CircularService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item, ref: ref)
    service.attributes = params.expect(item: [*Gws::Workflow::CircularService::PERMIT_PARAMS])
    unless service.call
      render template: "edit"
      return
    end

    flash[:notice] = t("workflow.notice.seen")
    render json: { status: 302, location: ref }, status: :ok, content_type: json_content_type
  end
  # rubocop:enable Rails/ActionControllerFlashBeforeRender
end
