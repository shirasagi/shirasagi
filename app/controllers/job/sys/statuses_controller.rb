class Job::Sys::StatusesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::TasksFilter

  model Job::Service
  navi_view "job/sys/main/navi"
  menu_view nil

  before_action :filter_permission
  helper_method :job_stucked?

  private

  def set_crumbs
    @crumbs << [t("job.status"), action: :show]
  end

  def filter_permission
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end

  def set_item
    name = Job::Service.config.name
    @item = Job::Service.where(name: name).order_by(updated: -1).first
  end

  def job_stucked?
    @model.stucked?
  end
end
