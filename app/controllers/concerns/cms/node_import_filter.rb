module Cms::NodeImportFilter
  extend ActiveSupport::Concern

  private

  def set_task
    opts = { name: task_name, site_id: @cur_site.id }
    opts[:node_id] = @cur_node.id if @cur_node
    @task = Cms::Task.find_or_create_by opts
  end

  def task_name
    "cms:import_nodes"
  end

  def job_bindings
    bindings = { site_id: @cur_site.id, user_id: @cur_user.id }
    bindings[:node_id] = @cur_node.id if @cur_node
    bindings
  end

  public

  def download
    return if request.get?

    csv_params = params.require(:item).permit(:encoding)

    criteria = @model.site(@cur_site)
    criteria = @cur_node ? criteria.node(@cur_node) : criteria.where(depth: 1)
    criteria = criteria.allow(:read, @cur_user, site: @cur_site, node: @cur_node)

    exporter = Cms::NodeExporter.new(site: @cur_site, criteria: criteria)
    enumerable = exporter.enum_csv(csv_params)

    filename = @model.to_s.tableize.tr("/", "_")
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def import
    raise "403" unless Cms::Tool.allowed?(:read, @cur_user, site: @cur_site)

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
end
