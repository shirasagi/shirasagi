class Gws::Schedule::UserPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_user

  navi_view "gws/schedule/main/navi"

  private

  def set_user
    @user ||= Gws::User.site(@cur_site).find(params[:user])
    raise '404' unless @user.active?
    raise '403' unless @user.readable?(@cur_user, site: @cur_site, permission: false)
  end

  def pre_params
    super.merge member_ids: [@user.id]
  end

  def redirection_view
    return 'month' if params.dig(:calendar, :view) == 'timelineDay'
    super
  end

  def set_items
    set_user
    @items ||= begin
      Gws::Schedule::Plan.site(@cur_site).without_deleted.
        member(@user).
        search(params[:s])
    end
  end

  public

  def events
    @items = Gws::Schedule::Plan.site(@cur_site).without_deleted.
      member(@user).
      search(params[:s])

    @todos = Gws::Schedule::Todo.site(@cur_site).without_deleted.
      member(@user).
      search(params[:s])
  end
end
