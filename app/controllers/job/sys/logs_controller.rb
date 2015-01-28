class Job::Sys::LogsController < ApplicationController
  include Sys::BaseFilter
  include Job::LogsFilter

  private
    def filter_permission
      raise "403" unless Sys::User.allowed?(:edit, @cur_user)
    end
end
