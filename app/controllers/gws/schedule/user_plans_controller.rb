class Gws::Schedule::UserPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_user

  navi_view "gws/schedule/main/navi"

  private

  def set_user
    @user ||= Gws::User.site(@cur_site).find(params[:user])
    raise '404' unless @user.active?
    raise '403' unless @user.readable_user?(@cur_user, site: @cur_site)
  end

  def pre_params
    super.merge member_ids: [@user.id]
  end

  #def redirection_view
  #  return 'month' if params.dig(:calendar, :view) == 'timelineDay'
  #  super
  #end

  def set_items
    set_user
    @items ||= begin
      Gws::Schedule::Plan.site(@cur_site).without_deleted.
        member(@user).
        search(@search_plan)
    end
  end

  public

  def events
    @items = Gws::Schedule::Plan.site(@cur_site).without_deleted.
      member(@user).
      search(@search_plan)

    todo_search = OpenStruct.new(params[:s])
    todo_search.category_id = nil if todo_search.category_id.present?

    @todos = Gws::Schedule::Todo.site(@cur_site).without_deleted.
      member(@user).
      search(todo_search)

    @works = Gws::Workload::Work.site(@cur_site).without_deleted.
      member(@user)
  end
end
