class Gws::Schedule::GroupsController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  def index
    @items = @cur_site.descendants.active.tree_sort(root_name: @cur_site.name)
  end
end
