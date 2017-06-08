class Gws::Schedule::CustomGroupPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_group

  private

  def set_group
    @group = Gws::CustomGroup.site(@cur_site).find params[:group]
  end

  def redirection_view
    'timelineDay'
  end

  public

  def index
    @items = @group.sorted_members
  end
end
