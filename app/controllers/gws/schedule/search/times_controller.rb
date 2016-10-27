class Gws::Schedule::Search::TimesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def get_params
      return fix_params if params[:s].blank?
      params.require(:s).permit(Gws::Schedule::PlanSearch.permitted_fields).merge(fix_params)
    end

  public
    def index
      @s = get_params

      @time_search = Gws::Schedule::PlanSearch.new(@s)
      @time_search.valid?

      @items = @time_search.search
    end
end
