class Workflow::Frames::BranchesController < ApplicationController
  include Cms::BaseFilter

  layout "ss/item_frame"

  before_action :set_frame_id

  helper_method :item, :css_class

  private

  def set_item
  end

  def set_frame_id
    @frame_id = "workflow-branch-frame"
  end

  def item
    @item ||= begin
      item = Cms::Page.site(@cur_site).find(params[:id])
      item.cur_node = item.parent
      item
    end
  end

  def css_class
    item.branch? ? "master" : "branch"
  end

  public

  def show
    render
  end

  def create
    if item.branch?
      render action: :show, status: :bad_request
      return
    end

    service = Workflow::BranchCreationService.new(cur_site: @cur_site, item: item)
    result = service.call
    unless result
      render action: :show, status: :unprocessable_entity
      return
    end

    item.reload
    @success_notice = t("workflow.notice.created_branch_page")
    render action: :show
  end
end
