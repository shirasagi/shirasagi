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
      @items = @group.users.order_by_title(@cur_site).compact
    end
end
