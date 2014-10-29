module SS::ExecFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_item
  end

  public
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

      require "open3"
      cmd = "bundle exec #{task_command} &"
      stdin, stdout, stderr = Open3.popen3(cmd)

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
