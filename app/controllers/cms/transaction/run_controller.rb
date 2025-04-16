class Cms::Transaction::RunController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter

  navi_view "cms/main/navi"

  private

  def job_class
    Cms::TransactionJob
  end

  def job_bindings
    { site_id: @cur_site.id }
  end

  def job_options
    { plan_id: @plan.id }
  end

  def task_name
    job_class.task_name
  end

  def set_item
    @plan = Cms::Transaction::Plan.find(params[:plan_id])
    @item = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id
  end

  public

  def index
    respond_to do |format|
      format.html { render template: 'cms/generate_nodes/index' }
      format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @item } }
    end
  end
end
