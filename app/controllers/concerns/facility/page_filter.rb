require "csv"

module Facility::PageFilter
  extend ActiveSupport::Concern

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "facility:import_node_pages"
  end

  def download
    @items = Facility::Node::Page.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site, node: @cur_node).
      where(filename: /^#{::Regexp.escape(@cur_node.filename)}\//, depth: @cur_node.depth + 1)
    csv = @items.to_csv.encode("SJIS", invalid: :replace, undef: :replace)

    send_data csv, filename: "facility_node_pages_#{Time.zone.now.to_i}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node)

    set_task

    @item = @cur_node

    if request.get?
      respond_to do |format|
        format.html { render }
        format.json { render json: @task.to_json(methods: :head_logs) }
      end
      return
    end

    begin
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        raise I18n.t("facility.import.invalid_file")
      end
      if !Facility::Node::Importer.valid_csv?(file)
        raise I18n.t("errors.messages.malformed_csv")
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "facility/file"
      ss_file.save

      # call job
      Facility::ImportJob.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(ss_file.id)
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
