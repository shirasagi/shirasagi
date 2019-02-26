class Job::Sns::TasksController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter
  include Job::TasksFilter

  model SS::Task
  navi_view "job/sns/main/navi"

  private

  def filter_permission
  end

  def item_criteria
    @model.where(user_id: @cur_user.id).exists(at: false)
  end
end
