class Job::Sys::MicheckerResultsController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Job::TasksFilter
  include Job::MicheckerResultFilter

  model Cms::Michecker::Result
  navi_view 'job/sys/main/navi'

  private

  def filter_permission
    raise "404" if SS.config.michecker.blank? || SS.config.michecker['disable']
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
  end

  def item_criteria
    @model.all.order_by(michecker_last_executed_at: -1)
  end
end
