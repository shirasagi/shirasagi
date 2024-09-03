class Gws::Workflow2::Frames::CirculationsController < ApplicationController
  include Gws::ApiFilter

  layout "ss/item_frame"
  model Gws::Workflow2::File

  before_action :set_frame_id
  before_action :check_commentable

  helper_method :ref, :workflow_circulation

  private

  def set_frame_id
    @frame_id = "workflow-circulation-frame"
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

  def check_commentable
    if !@item.readable?(@cur_user, site: @cur_site) || @item.workflow_state != "approve"
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

  def update
    service = Gws::Workflow2::CircularService.new(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user, item: @item, ref: ref)
    service.attributes = params.require(:item).permit(*Gws::Workflow2::CircularService::PERMIT_PARAMS)
    unless service.call
      render template: "edit"
      return
    end

    flash[:notice] = t("gws/workflow2.notice.seen")
    render json: { status: 302, location: ref }, status: :ok, content_type: json_content_type
  end
end
