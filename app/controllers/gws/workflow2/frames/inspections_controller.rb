class Gws::Workflow2::Frames::InspectionsController < ApplicationController
  include Gws::ApiFilter

  layout "ss/item_frame"
  model Gws::Workflow2::File

  before_action :set_frame_id
  before_action :check_approvable

  helper_method :ref

  private

  def set_frame_id
    @frame_id = "workflow-inspection-frame"
  end

  def check_approvable
    if !@item.readable?(@cur_user, site: @cur_site) || @item.workflow_state != "request"
      head :not_found
      return
    end

    workflow_approver = @item.find_workflow_request_to(@cur_user)
    if workflow_approver.blank?
      head :not_found
      return
    end

    expected_states = %w(request)
    if @item.workflow_pull_up == "enabled"
      expected_states << 'pending'
    end
    unless expected_states.include?(workflow_approver[:state])
      head :not_found
    end
  end

  def ref
    @ref ||= begin
      ref = params[:ref].to_s
      if ref.present? && !Sys::TrustedUrlValidator.valid_url?(ref)
        ref = nil
      end

      ref || gws_workflow2_file_path(state: 'all', id: @item)
    end
  end

  public

  def update
    if params.key?(:approve)
      service_class = Gws::Workflow2::ApproveService
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
    unless service.call
      render template: "edit"
      return
    end

    flash[:notice] = notice
    render json: { status: 302, location: ref }, status: :ok, content_type: json_content_type
  end
end
