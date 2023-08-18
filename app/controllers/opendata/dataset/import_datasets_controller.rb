class Opendata::Dataset::ImportDatasetsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::Dataset

  navi_view "opendata/main/navi"
  menu_view nil

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "opendata:import_datasets"
  end

  public

  def import
    raise "403" unless Opendata::Dataset.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node)

    set_task

    @item = @model.new

    if request.get? || request.head?
      respond_to do |format|
        format.html { render }
        format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @task } }
      end
      return
    end

    begin
      file = params.dig(:item, :file)
      if file.nil? || ::File.extname(file.original_filename) != ".zip"
        raise I18n.t("errors.messages.invalid_zip")
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "opendata/import"
      ss_file.save

      # call job
      Opendata::Dataset::ImportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(ss_file.id)
    rescue => e
      @item.errors.add :base, e.to_s
    end

    if @item.errors.present?
      render
    else
      redirect_to({ action: :import }, { notice: I18n.t("ss.notice.started_import") })
    end
  end
end
