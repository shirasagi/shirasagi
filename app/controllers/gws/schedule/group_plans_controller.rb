class Gws::Schedule::GroupPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_group

  private
    def set_group
      @group = Gws::Group.site(@cur_site).find params[:group]
    end

  public
    def index
      @items = @group.users.order_by("title_orders.#{@cur_site.id}" => 1, name: 1).compact
    end
end
