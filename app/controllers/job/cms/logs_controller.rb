class Job::Cms::LogsController < ApplicationController
  include Cms::BaseFilter
  include Job::LogsFilter

  navi_view "cms/main/navi"

  private
    def filter_permission
      raise "403" unless Cms::User.allowed?(:edit, @cur_user, site: @cur_site)
    end
end
