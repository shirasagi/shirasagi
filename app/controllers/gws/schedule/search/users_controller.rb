class Gws::Schedule::Search::UsersController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  def index
    @items = []
    return if params.dig(:s, :keyword).blank?

    @items = Gws::User.site(@cur_site).
      active.
      search(params[:s]).
      order_by_title(@cur_site)
  end
end
