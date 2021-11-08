module SS::JobFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_item
  end

  def index
    respond_to do |format|
      format.html { render template: "ss/tasks/index" }
      format.json { render template: "ss/tasks/index", content_type: json_content_type, locals: { item: @item } }
    end
  end

  def job_class
    raise NotImplementedError
  end

  def job_bindings
    {}
  end

  def job_options
    {}
  end

  def run
    return stop if params[:stop]
    return reset if params[:reset]
    return redirect_to({ action: :index }) if @item.running?

    @item.ready
    job_class.bind(job_bindings).perform_later(job_options)

    redirect_to({ action: :index }, { notice: t("ss.tasks.started") })
  end

  def stop
    @item.update interrupt: "stop"
    redirect_to({ action: :index }, { notice: t("ss.tasks.interrupted") })
  end

  def reset
    @item.destroy
    redirect_to({ action: :index }, { notice: t("ss.notice.deleted") })
  end

  def download_logs
    # unable to download
    raise "404" unless @item.respond_to?(:log_file_path)

    send_file @item.log_file_path, type: 'text/plain', filename: "#{@item.id}.log",
              disposition: :attachment, x_sendfile: true
  end
end
