module SS::JobFilter
  extend ActiveSupport::Concern

  included do
    attr_accessor :job_class
    attr_accessor :job_bindings
    attr_accessor :job_options
    before_action :set_item
  end

  def index
    respond_to do |format|
      format.html { render file: "ss/tasks/index" }
      format.json { render json: @item.to_json }
    end
  end

  def run
    return stop if params[:stop]
    return reset if params[:reset]
    return redirect_to({ action: :index }) if @item.running?

    @item.update_attributes state: "ready"
    @job_class.bind(@job_bindings).perform_later(@job_options)

    redirect_to({ action: :index }, { notice: t("views.task.started") })
  end

  def stop
    @item.update_attributes interrupt: "stop"
    redirect_to({ action: :index }, { notice: t("views.task.interrupted") })
  end

  def reset
    @item.destroy
    redirect_to({ action: :index }, { notice: t("views.notice.deleted") })
  end
end
