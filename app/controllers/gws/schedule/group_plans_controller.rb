class Gws::Schedule::GroupPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_group
  before_action :set_items

  private

  def set_group
    @group = Gws::Group.site(@cur_site).find params[:group]
    raise '404' unless @group.active?
  end

  def set_items
    @items = @group.users.active.order_by_title(@cur_site).compact
  end

  def redirection_view
    'timelineDay'
  end

  public

  def index
  end
end
