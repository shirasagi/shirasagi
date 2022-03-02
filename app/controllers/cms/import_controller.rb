class Cms::ImportController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::ImportJobFile

  navi_view "cms/main/navi"
  menu_view nil

  private

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
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

    if request.get? || request.head?
      respond_to do |format|
        format.html { render }
        format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @task } }
      end
      return
    end

    @item = @model.new get_params
    render_create @item.save_with_import, location: { action: :import },
      render: { template: "import" }, notice: t("ss.notice.started_import")
  end

  def download_logs
    raise "403" unless Cms::Node.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

    set_task

    send_file @task.log_file_path, type: 'text/plain', filename: "#{@task.id}.log",
              disposition: :attachment, x_sendfile: true
  end
end
