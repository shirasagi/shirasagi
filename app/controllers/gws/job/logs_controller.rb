class Gws::Job::LogsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include ::Job::LogsFilter

  model Gws::Job::Log

  navi_view 'gws/job/main/conf_navi'

  private

  def filter_permission
    raise "403" unless Gws::Job::Log.allowed?(:read, @cur_user, site: @cur_site)
  end
end
