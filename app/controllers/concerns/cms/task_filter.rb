module Cms::TaskFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_item
  end

  public
    def index
      render file: "cms/generate_pages/index"
    end

    def run
      return stop if params[:stop]
      return reset if params[:reset]
      return redirect_to({ action: :index }) if @item.running?

      cmd = "bundle exec #{task_command} &"

      require "open3"
      stdin, stdout, stderr = Open3.popen3(cmd)

      redirect_to({ action: :index }, { notice: t("ss.task.started") })
    end

    def stop
      @item.update_attributes interrupt: "stop"
      redirect_to({ action: :index }, { notice: t("ss.task.interrupted") })
    end

    def reset
      @item.destroy
      redirect_to({ action: :index }, { notice: t(:deleted) })
    end
end
