class Cms::Node::GeneratePagesController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter
  include Cms::GenerateJobFilter

  navi_view "cms/node/main/navi"

  private

  def job_class
    Cms::Page::GenerateJob
  end

  def job_bindings
    {
      site_id: @cur_site.id,
      node_id: @cur_node.id
    }
  end

  def task_name
    job_class.task_name
  end

  def set_item
    @item = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id, segment: nil
  end

  public

  def index
    respond_to do |format|
      format.html { render template: 'cms/generate_nodes/index' }
      format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @item } }
    end
  end
end
