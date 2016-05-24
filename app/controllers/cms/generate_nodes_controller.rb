class Cms::GenerateNodesController < ApplicationController
  include Cms::BaseFilter
  include SS::JobFilter

  navi_view "cms/main/navi"

  private
    def job_class
      Cms::Node::GenerateJob
    end

    def job_bindings
      {
        site_id: @cur_site.id,
      }
    end

    def task_name
      job_class.task_name
    end

    def set_item
      @item = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: nil
    end
end
