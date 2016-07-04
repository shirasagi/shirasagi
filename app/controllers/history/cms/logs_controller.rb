class History::Cms::LogsController < ApplicationController
  include Cms::BaseFilter
  include History::LogFilter::View

  model History::Log

  navi_view "cms/main/conf_navi"

  before_action :filter_permission
  skip_action_callback :put_log

  private
    def set_crumbs
      @crumbs << [:"history.log", action: :index]
    end

    def filter_permission
      raise "403" unless Cms::Tool.allowed?(:edit, @cur_user, site: @cur_site)
    end

    def cond
      { site_id: @cur_site.id }
    end
end
