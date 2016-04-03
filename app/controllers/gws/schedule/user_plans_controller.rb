class Gws::Schedule::UserPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_user

  private
    def set_user
      @user = Gws::User.site(@cur_site).find(params[:user])
    end

    def pre_params
      super.merge member_ids: [@user.id]
    end

  public
    def events
      @items = Gws::Schedule::Plan.site(@cur_site).
        member(@user).
        search(params[:s])
    end
end
