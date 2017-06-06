module SS::ExecFilter
  extend ActiveSupport::Concern

  included do
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

    SS::RakeRunner.run_async *task_command

    redirect_to({ action: :index }, { notice: t("ss.tasks.started") })
  end

  def stop
    @item.update_attributes interrupt: "stop"
    redirect_to({ action: :index }, { notice: t("ss.tasks.interrupted") })
  end

  def reset
    @item.destroy
    redirect_to({ action: :index }, { notice: t("ss.notice.deleted") })
  end
end

SS.deprecate_constant 'ExecFilter'
