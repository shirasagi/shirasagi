module Job::LogsFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    model Job::Log
    before_action :filter_permission
    before_action :set_ymd
    before_action :set_search_params
    before_action :set_item, only: [:show]
    helper_method :min_updated
    helper_method :class_name_options
  end

  private

  def set_crumbs
    @crumbs << [t("job.log"), action: :index]
  end

  def set_ymd
    @ymd = params[:ymd]
  end

  def set_search_params
    @s ||= OpenStruct.new(params[:s])
  end

  def log_criteria
    @log_criteria ||= begin
      criteria = @model.all
      criteria = criteria.site(@cur_site) if @cur_site
      criteria = criteria.search_ymd(ymd: @ymd, term: '1.day') if @ymd.present?
      criteria
    end
  end

  def set_item
    @item = log_criteria.find(params[:id])
    raise "404" unless @item
  end

  def min_updated
    keep_logs = SS.config.job.keep_logs
    Time.zone.now - keep_logs
  end

  def class_name_options
    @class_name_options ||= begin
      pipes = []
      pipes << { "$match" => log_criteria.selector }
      pipes << { "$group" => {
        _id: "$class_name",
        count: { "$sum" => 1 }
      } }
      pipes << { "$sort" => { "count" => -1, "_id" => 1 } }

      data = @model.collection.aggregate(pipes)
      data.map do |d|
        id = d["_id"]
        count = d["count"]
        humanized_id = I18n.t("job.models.#{id.underscore}", default: id)
        [ "#{humanized_id} (#{count.to_s(:delimited)})", id ]
      end
    end
  end

  public

  def index
    @items = log_criteria.search(@s).order_by(updated: -1).page(params[:page]).per(50)
  end

  def show
    render
  end

  def download
    set_item
    raise '404' if !::File.exist?(@item.file_path)
    send_file @item.file_path, type: 'text/plain', filename: "#{@item.id}.log",
              disposition: :attachment, x_sendfile: true
  end

  def download_all
    @item = @model.new(save_term: "1.day")
    # show condition input form if request is get.
    return if request.get? || request.head?

    save_term = params.require(:item).permit(:save_term)[:save_term]

    @items = log_criteria
    if @ymd.blank? && save_term.present?
      from = Time.zone.now - SS::Duration.parse(save_term)
      @items = @items.gte(updated: from)
    end
    @items = @items.reorder(closed: 1)

    send_csv @items
  rescue
    raise "400"
  end

  def batch_destroy
    @item = @model.new
    @item.save_term = "6.months"
    # show condition input form if request is get.
    return if request.get? || request.head?

    save_term = params.require(:item).permit(:save_term)[:save_term]

    items = log_criteria
    if save_term.present?
      from = Time.zone.now - SS::Duration.parse(save_term)
      items = items.lt(created: from)
    end
    num = items.destroy_all

    compact unless Rails.env.test?

    render_destroy num
  rescue
    raise "400"
  end

  private

  def send_csv(items)
    csv = build_csv(items)
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "job_logs_#{Time.zone.now.to_i}.csv"
  end

  def build_csv(items)
    require "csv"

    I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << %w(ClassName Started Closed State Args Logs)
        items.each do |item|
          class_name = item.class_name.underscore
          data << [
            t(class_name, scope: "job.models", default: class_name.humanize),
            item.start_label,
            item.closed_label,
            t(item.state, scope: "job.state"),
            item.args,
            item.joined_jobs
          ]
        end
      end
    end
  end

  def render_destroy(result, opts = {})
    location = opts[:location].presence || { action: :index }

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: t("ss.notice.deleted") }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render template: "delete" }
        format.json { render json: :error, status: :unprocessable_entity }
      end
    end
  end

  def compact
    coll = @model.collection
    coll.client.command({ compact: coll.name }) rescue nil
  end
end
