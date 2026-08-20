class Article::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter
  include Cms::OpendataRef::PageFilter
  include SS::TurboFrameFilter

  model Article::Page

  append_view_path "app/views/cms/pages"
  navi_view "article/main/navi"

  before_action(only: %i[new create edit update]) { @auto_save_enabled = true }

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "article:import_pages"
  end

  public

  def download_all
    @item = Article::Page::ExporterParam.new(fix_params)
    if request.get? || request.head?
      render template: "file_gen", layout: "ss/item_frame"
      return
    end

    @item.attributes = params.require(:item).permit(:encoding, :form_id, :truncate)
    if @item.invalid?
      render template: "file_gen", layout: "ss/item_frame"
      return
    end

    task = Cms::FileGenTask.new(cur_site: @cur_site, cur_user: @cur_user)
    task.name = "article_pages_download_#{@cur_user.id}_#{Time.zone.now.to_i}"
    task.file_basename = "article_pages"
    task.file_format = "csv"
    task.params = @item.attributes.as_json
    task.save!

    job_class = Article::Page::ExportJob.bind(site_id: @cur_site, user_id: @cur_user, node_id: @cur_node, task_id: task)
    job_class.perform_later

    redirect_to sns_frames_file_gen_task_status_path(id: task)
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
      if SS::Csv.detect_encoding(file) == Encoding::ASCII_8BIT
        raise I18n.t("errors.messages.unsupported_encoding")
      end
      if !Article::Page::Importer.valid_csv?(file)
        raise I18n.t("errors.messages.malformed_csv")
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "article/import"
      ss_file.save

      # call job
      Article::Page::ImportJob.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(ss_file.id)
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
