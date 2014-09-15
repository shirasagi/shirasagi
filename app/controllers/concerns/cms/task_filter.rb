# coding: utf-8
module Cms::TaskFilter
  extend ActiveSupport::Concern

  included do
    navi_view "cms/main/navi"
    before_action :set_item
    before_action :set_command
  end

  public
    def index
      render file: "cms/generate_pages/index"
    end

    def run
      require "open3"
      stdin, stdout, stderr = Open3.popen3(@cmd)

      redirect_to({ action: :index }, { notice: t(:started) })
    end
end
