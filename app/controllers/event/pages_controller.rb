class Event::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Event::Page

  append_view_path "app/views/cms/pages"
  navi_view "event/main/navi"

  before_action :change_node_type

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def change_node_type
    @cur_node = @cur_node.becomes_with_route if @cur_node.class == Cms::Node
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "event:import_pages"
  end

  public

  def download
    csv = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user, site: @cur_site, node: @cur_node).to_csv.encode("SJIS", invalid: :replace, undef: :replace)
    filename = @model.to_s.tableize.gsub(/\//, "_")
    send_data csv, filename: "#{filename}_#{Time.zone.now.to_i}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

    set_task

    @item = @model.new

    if request.get?
      respond_to do |format|
        format.html { render }
        format.json { render json: @task.to_json(methods: :head_logs) }
      end
      return
    end

    file = params[:item].try(:[], :file)
    file_type = nil
    if file.present?
      file_type = SS::MimeType.find(file.original_filename, nil)
    end

    if file_type == "text/comma-separated-values"
      # check CSV
      if !Event::Page::CsvImporter.valid_csv?(file)
        @item.errors.add :base, :malformed_csv
        return
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "event/import"
      ss_file.save

      # call job
      Event::Page::ImportJob.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(ss_file.id)
      redirect_to({ action: :import }, { notice: I18n.t("ss.notice.started_import") })
      return
    end

    if file_type == "text/calendar"
      # check ical
      if !Event::Page::IcalImporter.validate_ical(file.path)
        @item.errors.add :base, :malformed_ical
        return
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "event/import"
      ss_file.save

      # call job
      job = Event::Ical::ImportJob.bind(site_id: @cur_site.id, node_id: @cur_node.id, user_id: @cur_user.id)
      job.perform_later(ss_file.id, sync: false)
      redirect_to({ action: :import }, { notice: I18n.t("ss.notice.started_import") })
      return
    end

    @item.errors.add :base, :invalid_csv_or_ical
  end

  def ical_refresh
    return if request.get?
    job = Event::Ical::ImportJob.bind(site_id: @cur_site.id, node_id: @cur_node.id, user_id: @cur_user.id)
    job.perform_later
    redirect_to({ action: :index }, { notice: t("rss.messages.job_started") })
  end
end
