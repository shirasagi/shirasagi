class Job::Cms::LogsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Job::LogsFilter

  navi_view "job/cms/main/navi"

  private
    def filter_permission
      raise "403" unless Cms::Tool.allowed?(:edit, @cur_user, site: @cur_site)
    end
end
