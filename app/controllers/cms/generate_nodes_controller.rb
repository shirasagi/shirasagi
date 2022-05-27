class Cms::GenerateNodesController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter
  include Cms::GenerateJobFilter

  navi_view "cms/main/navi"

  private

  def job_class
    Cms::Node::GenerateJob
  end

  def job_bindings
    { site_id: @cur_site.id }
  end

  def task_name
    job_class.task_name
  end

  def generate_segments
    @cur_site.generate_node_segments
  end

  public

  def index
    respond_to do |format|
      format.html { render }
      format.json do
        render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @item }
      end
    end
  end
end
