class Gws::Discussion::TodosController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  model Gws::Schedule::Todo

  before_action :set_item, only: [ :show, :edit, :update, :delete, :destroy, :disable, :finish, :revert ]
  before_action :set_forum

  private

  def set_forum
    @forum = Gws::Discussion::Forum.find(params[:forum_id])
  end

  def set_crumbs
    @crumbs << [t('modules.gws/discussion'), gws_discussion_main_path]
  end

  def pre_params
    @skip_default_group = true
    {
      start_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00'),
      member_ids: params[:member_ids].presence || [@cur_user.id],
    }
  end

  def fix_params
    set_forum
    { cur_user: @cur_user, cur_site: @cur_site, discussion_forum_id: @forum.id }
  end

  public

  def index
    @items = []
  end

  def print
    @items = Gws::Schedule::Todo.
        site(@cur_site).
        discussion_forum(@forum).
        allow(:read, @cur_user, site: @cur_site).
        active().
        search(params[:s])

    render layout: 'ss/print'
  end

  def events
    @start_at = params[:s][:start].to_date
    @end_at = params[:s][:end].to_date

    @todos = Gws::Schedule::Todo.
      site(@cur_site).
      discussion_forum(@forum).
      allow(:read, @cur_user, site: @cur_site).
      active().
      search(params[:s]).
      map do |todo|
        result = todo.calendar_format(@cur_user, @cur_site)
        result[:restUrl] = gws_discussion_forum_todos_path(site: @cur_site.id)
        result
      end

    @holidays = HolidayJapan.between(@start_at, @end_at).map do |date, name|
      { className: 'fc-holiday', title: "  #{name}", start: date, allDay: true, editable: false, noPopup: true }
    end

    @items = @todos + @holidays
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_create @item.save, location: { action: :index }
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_update @item.update, location: { action: :index }
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable
  end

  def finish
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(todo_state: 'finished')
  end

  def revert
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update(todo_state: 'unfinished')
  end
end
