class Job::Sys::ReservationsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::TasksFilter

  model Job::Task
  navi_view 'job/sys/main/navi'

  private

  def set_crumbs
    @crumbs << [t("job.main"), job_sys_main_path]
    @crumbs << [t("job.reservation"), action: :index]
  end

  def filter_permission
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end

  def set_deletable
    @deletable ||= SS::User.allowed?(:edit, @cur_user)
  end

  def item_criteria
    @model.exists(at: true).order_by(at: 1, created: 1)
  end
end
