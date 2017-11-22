class Gws::Schedule::UserPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_user

  private

  def set_user
    @user = Gws::User.site(@cur_site).find(params[:user])
    raise '404' unless @user.active?
  end

  def pre_params
    super.merge member_ids: [@user.id]
  end

  def redirection_view
    return 'month' if params.dig(:calendar, :view) == 'timelineDay'
    super
  end

  public

  def events
    @items = Gws::Schedule::Plan.site(@cur_site).
      member(@user).
      search(params[:s])
  end
end
