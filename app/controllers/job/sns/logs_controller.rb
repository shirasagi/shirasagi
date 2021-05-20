class Job::Sns::LogsController < ApplicationController
  include ::Sns::BaseFilter
  include ::Sns::CrudFilter
  include Job::LogsFilter

  navi_view "job/sns/main/navi"

  private

  def set_crumbs
    @crumbs << [t("job.task_manager"), action: :index]
    @crumbs << [t("job.log"), action: :index]
  end

  def filter_permission
  end

  def log_criteria
    criteria = @model.where(user_id: @cur_user.id)
    criteria = criteria.search_ymd(ymd: @ymd) if @ymd.present?
    criteria
  end
end
