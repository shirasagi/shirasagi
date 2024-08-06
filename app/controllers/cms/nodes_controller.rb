class Cms::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Cms::Node

  navi_view "cms/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.node"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
  end

  def pre_params
    { route: "cms/node" }
  end

  def redirect_url
    nil
  end

  # TODO: If the code is the same in Cms::Node::NodesController, integrate it into a concers module
  def set_task
    @task = Cms::Task.find_or_create_by name: task_name, site_id: @cur_site.id
  end

  def task_name
    "cms:import_nodes"
  end

  def job_bindings
    {
      site_id: @cur_site.id,
      user_id: @cur_user.id
    }
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(depth: 1).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end

  # TODO: Implement download
  def download
    return if request.get?

    csv_params = params.require(:item).permit(:encoding)

    # TODO and Memo:
    # this controller is implementation of root node actions.
    # so need to searching depth 1 nodes.
    # but this criteria is searching all depth nodes.
    criteria = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site, node: @cur_node)

    exporter = Cms::NodeExporter.new(mode: "article", site: @cur_site, criteria: criteria)
    enumerable = exporter.enum_csv(csv_params)

    filename = @model.to_s.tableize.tr("/", "_")
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  # TODO: Implement import referring to Article::PagesController#import
  def import
    # TODO: Implement import permission
    #raise "403" unless @model.allowed?(:import, @cur_user, site: @cur_site, node: @cur_node, owned: true)

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
      # TODO: Implement import validations
      file = params[:item].try(:[], :file)
      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        raise I18n.t("errors.messages.invalid_csv")
      end
      if SS::Csv.detect_encoding(file) == Encoding::ASCII_8BIT
        raise I18n.t("errors.messages.unsupported_encoding")
      end
      #if !Article::Page::Importer.valid_csv?(file)
      #  raise I18n.t("errors.messages.malformed_csv")
      #end

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "cms/import_nodes"
      ss_file.save

      # call job
      Cms::Node::ImportJob.bind(job_bindings).perform_later(ss_file.id)
    rescue => e
      @item.errors.add :base, e.to_s
    end

    if @item.errors.present?
      render
    else
      redirect_to({ action: :import }, { notice: I18n.t("ss.notice.started_import") })
    end
  end

  def routes
    @items = {}

    Cms::Node.new.route_options.each do |name, path|
      mod = path.sub(/\/.*/, '')
      @items[mod] = { name: t("modules.#{mod}"), items: [] } if !@items[mod]
      @items[mod][:items] << [ name.sub(/.*\//, ""), path ]
    end

    render layout: "ss/ajax"
  end
end
