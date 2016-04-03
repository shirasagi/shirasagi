class Cms::GenerateNodesController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter

  navi_view "cms/main/navi"

  private
    def task_name
      "cms:generate_nodes"
    end

    def set_item
      @item = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: nil
      @job_class = Cms::Node::GeneratorJob
      @job_bindings = {
        site_id: @cur_site,
      }
      @job_options = {}
    end
end
