class Gws::Job::UserReservationsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include ::Job::TasksFilter

  model ::Job::Task

  navi_view 'gws/job/main/navi'
  menu_view 'gws/job/reservations/menu'

  private

  def set_crumbs
    @crumbs << [t("job.task_manager"), gws_job_user_main_path]
    @crumbs << [t("job.reservation"), action: :index]
  end

  def append_view_paths
    append_view_path "app/views/gws/job/reservations"
    super
  end

  def filter_permission
  end

  def item_criteria
    criteria = @model.group(@cur_site).exists(at: true)
    criteria = criteria.where(user_id: @cur_user.id)
    criteria.order_by(at: 1, created: 1)
  end
end
