class Gws::Schedule::UserPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_user

  private
    def set_user
      @user = Gws::User.site(@cur_site).find(params[:user])
    end

  public
    def index
      @items = Gws::Schedule::Plan.site(@cur_site).
        member(@user).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s])
    end
end
