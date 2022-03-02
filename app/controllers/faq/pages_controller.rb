class Faq::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Faq::Page

  append_view_path "app/views/cms/pages"
  navi_view "faq/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "faq:import_pages"
  end

  public

  def new
    super
    @item.question = params[:question].to_s
  end

  def download
    criteria = @model.site(@cur_site).node(@cur_node)
    criteria = criteria.allow(:read, @cur_user, site: @cur_site, node: @cur_node)

    exporter = Cms::PageExporter.new(mode: "faq", site: @cur_site, criteria: criteria)
    enumerable = exporter.enum_csv(encoding: "Shift_JIS")

    filename = @model.to_s.tableize.tr("/", "_")
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def import
    raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

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
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        raise I18n.t("errors.messages.invalid_csv")
      end
      if !Faq::Page::Importer.valid_csv?(file)
        raise I18n.t("errors.messages.malformed_csv")
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "faq/import"
      ss_file.save

      # call job
      Faq::Page::ImportJob.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(ss_file.id)
    rescue => e
      @item.errors.add :base, e.to_s
    end

    if @item.errors.present?
      render
    else
      redirect_to({ action: :import }, { notice: I18n.t("ss.notice.started_import") })
    end
  end

  def download_logs
    raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

    set_task

    send_file @task.log_file_path, type: 'text/plain', filename: "#{@task.id}.log",
              disposition: :attachment, x_sendfile: true
  end
end
