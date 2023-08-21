class Garbage::CenterListsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Center

  navi_view "garbage/center_lists/nav"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def redirect_url
    diff = (@item.route.pluralize != "garbage/centers")
    diff ? node_node_path(cid: @cur_node, id: @item.id) : { action: :show, id: @item.id }
  end

  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id, node_id: @cur_node.id
  end

  def task_name
    "garbage:import_node_centers"
  end

  def send_csv(items)
    require "csv"

    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << [
          @model.t(:filename),
          @model.t(:name),
          @model.t(:index_name),
          @model.t(:layout),
          @model.t(:order),
          @model.t(:groups)
        ]
        items.each do |item|
          row = []
          row << item.basename
          row << item.name
          row << item.index_name
          row << item.layout.try(:name)
          row << item.order
          row << item.groups.pluck(:name).join("_n")
          data << row
        end
      end
    end

    csv = "\uFEFF" + csv
    send_data csv.encode("UTF-8", invalid: :replace, undef: :replace),
      filename: "garbage_centers_#{Time.zone.now.strftime("%Y_%m%d_%H%M")}.csv"
  end

  public

  def download
    send_csv @cur_node.children
  end

  def import
    raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

    set_task

    if request.get? || request.head?
      respond_to do |format|
        format.html { render }
        format.json { render json: @task.to_json(methods: :head_logs) }
      end
      return
    end

    @item = @model.new

    begin
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        raise I18n.t("garbage.import.invalid_file")
      end
      if !Garbage::Node::CenterImporter.valid_csv?(file)
        raise I18n.t("errors.messages.malformed_csv")
      end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "garbage/center"
      ss_file.save

      # call job
      Garbage::CenterImportJob.bind(site_id: @cur_site, node_id: @cur_node, user_id: @cur_user).perform_later(ss_file.id)
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
