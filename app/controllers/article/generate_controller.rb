# coding: utf-8
class Article::GenerateController < ApplicationController
  include Cms::BaseFilter

  navi_view "article/main/navi"

  before_action :set_task

  private
    def set_task
      @model = Cms::Task

      @name = "cms:page:generate"
      @item = @model.find_or_create_by(name: @name, site_id: @cur_site.id, node_id: @cur_node.id)
    end

  public
    def index
      #
    end

    def run
      cmd = %(rake #{@name} site="#{@cur_site.host}" node="#{@cur_node.filename}" &)

      require "open3"
      stdin, stdout, stderr = Open3.popen3(cmd)

      redirect_to({ action: :index }, { notice: t(:started) })
    end
end
