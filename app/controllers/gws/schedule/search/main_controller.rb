class Gws::Schedule::Search::MainController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  def index
    @time_search = Gws::Schedule::PlanSearch.new
  end
end
