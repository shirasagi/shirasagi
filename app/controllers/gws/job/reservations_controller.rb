class Gws::Job::ReservationsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include ::Job::TasksFilter

  model ::Job::Task
  navi_view 'gws/job/main/conf_navi'

  private

  def filter_permission
    raise "403" unless Gws::Job::Log.allowed?(:read, @cur_user, site: @cur_site)
  end

  def item_criteria
    @model.group(@cur_site).exists(at: true).order_by(at: 1, created: 1)
  end
end
