class Job::Sns::LogsController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter
  include Job::LogsFilter

  navi_view "sns/main/navi"

  private

  def filter_permission
  end

  def log_criteria
    @model.where(user_id: @cur_user.id)
  end
end
