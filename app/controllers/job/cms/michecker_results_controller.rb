class Job::Cms::MicheckerResultsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Job::TasksFilter
  include Job::MicheckerResultFilter

  model Cms::Michecker::Result
  navi_view 'job/cms/main/navi'

  private

  def filter_permission
    raise "404" if SS.config.michecker.blank? || SS.config.michecker['disable']
    raise "403" unless Cms::Tool.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def item_criteria
    @model.site(@cur_site).order_by(michecker_last_executed_at: -1)
  end
end
