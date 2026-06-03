class Gws::Job::LogsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include ::Job::LogsFilter

  model Gws::Job::Log

  navi_view 'gws/job/main/conf_navi'

  private

  def set_crumbs
    @crumbs << [t("modules.gws/job"), gws_job_main_path]
    @crumbs << [t("gws/job.log"), action: :index]
  end

  def filter_permission
    raise "403" unless Gws::Job::Log.allowed?(:read, @cur_user, site: @cur_site)
  end
end
