class Gws::Job::UserLogsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include ::Job::LogsFilter

  model Gws::Job::Log

  navi_view 'gws/job/main/navi'
  menu_view 'gws/job/logs/menu'

  private

  def set_crumbs
    @crumbs << [t("job.task_manager"), gws_job_user_main_path]
    @crumbs << [t("job.log"), action: :index]
  end

  def append_view_paths
    append_view_path "app/views/gws/job/logs"
    super
  end

  def filter_permission
  end

  def log_criteria
    criteria = @model.site(@cur_site)
    criteria = criteria.where(user_id: @cur_user.id)
    criteria = criteria.search_ymd(ymd: @ymd, term: '1.day') if @ymd.present?
    criteria
  end
end
