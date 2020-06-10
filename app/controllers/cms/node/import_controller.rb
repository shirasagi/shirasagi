class Cms::Node::ImportController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::ImportJobFile

  navi_view "cms/node/import/navi"
  menu_view nil

  private

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, node: @cur_node }
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id
  end

  def task_name
    "cms:import_files"
  end

  public

  def import
    raise "403" unless Cms::Node.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

    set_task

    if request.get?
      respond_to do |format|
        format.html { render }
        format.json { render json: @task.to_json(methods: :head_logs) }
      end
      return
    end

    @item = @model.new get_params
    render_create @item.save_with_import, location: { action: :import },
      render: { file: :import }, notice: t("ss.notice.started_import")
  end
end
