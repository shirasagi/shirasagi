class Job::Sns::ReservationsController < ApplicationController
  include ::Sns::BaseFilter
  include ::Sns::CrudFilter
  include Job::TasksFilter

  model Job::Task
  navi_view "job/sns/main/navi"

  private

  def set_crumbs
    @crumbs << [t("job.task_manager"), action: :index]
    @crumbs << [t("job.reservation"), action: :index]
  end

  def filter_permission
  end

  def item_criteria
    @model.where(user_id: @cur_user.id).exists(at: true).order_by(at: 1, created: 1)
  end
end
