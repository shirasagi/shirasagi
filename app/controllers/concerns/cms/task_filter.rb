# coding: utf-8
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
      cmd = "bundle exec #{task_command} &"

      require "open3"
      stdin, stdout, stderr = Open3.popen3(cmd)

      redirect_to({ action: :index }, { notice: t(:started) })
    end
end
