class Job::Sys::MicheckerResultsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::TasksFilter
  include Job::MicheckerResultFilter

  model Cms::Michecker::Result
  navi_view 'job/sys/main/navi'

  private

  def set_crumbs
    @crumbs << [t("job.main"), job_sys_main_path]
    @crumbs << [Cms::Michecker::Result.model_name.human, action: :index]
  end

  def filter_permission
    raise "404" if SS.config.michecker.blank? || SS.config.michecker['disable']
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end

  def set_deletable
    @deletable ||= SS::User.allowed?(:edit, @cur_user)
  end

  def item_criteria
    @model.all.order_by(michecker_last_executed_at: -1)
  end
end
