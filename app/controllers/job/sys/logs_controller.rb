class Job::Sys::LogsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::LogsFilter

  navi_view "job/sys/main/navi"

  private

  def set_crumbs
    @crumbs << [t("job.main"), job_sys_main_path]
    @crumbs << [t("job.log"), action: :index]
  end

  def filter_permission
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end
end
