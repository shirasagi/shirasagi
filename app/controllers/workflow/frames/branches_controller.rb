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
    if item.branches.present?
      item.error.add :base, :branch_is_already_existed
      render action: :show, status: :bad_request
      return
    end

    task = SS::Task.find_or_create_for_model(item, site: @cur_site)

    result = nil
    rejected = -> do
      item.errors.add :base, :other_task_is_running
      result = false
    end
    task.run_with(rejected: rejected) do
      task.log "# #{I18n.t("workflow.branch_page")} #{I18n.t("ss.buttons.new")}"

      item.reload
      if item.branches.present?
        item.error.add :base, :branch_is_already_existed
        result = false
      else
        copy = item.new_clone
        copy.master = item
        result = copy.save
      end
    end

    unless result
      render action: :show, status: :unprocessable_entity
      return
    end

    item.reload
    @success_notice = t("workflow.notice.created_branch_page")
    render action: :show
  end
end
