class Job::Sys::LogsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::LogsFilter

  navi_view "job/sys/main/navi"

  private
    def filter_permission
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
    end

    def log_criteria
      @model.all
    end
end
