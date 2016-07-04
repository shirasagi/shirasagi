class History::Sys::LogsController < ApplicationController
  include Sys::BaseFilter
  include History::LogFilter::View

  model History::Log

  before_action :filter_permission

  private
    def set_crumbs
      @crumbs << [:"history.log", action: :index]
    end

    def filter_permission
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
    end

    def cond
      { site_id: nil }
    end
end
