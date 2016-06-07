class Job::Sys::LogsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::LogsFilter

  private
    def filter_permission
      raise "403" unless SS::User.allowed?(:edit, @cur_user)
    end
end
