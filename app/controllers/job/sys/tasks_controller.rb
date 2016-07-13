class Job::Sys::TasksController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::TasksFilter

  model SS::Task
  navi_view "job/sys/main/navi"

  private
    def filter_permission
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
    end
end
