class Gws::Schedule::GroupsController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  public
    def index
      @items = @cur_site.descendants
    end
end
