class Gws::Discussion::TodosController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::TodoFilter

  model Gws::Schedule::Todo

  before_action :set_forum
  before_action :set_crumbs

  navi_view "gws/discussion/main/navi"

  private

  def set_forum
    raise "403" unless Gws::Discussion::Forum.allowed?(:read, @cur_user, site: @cur_site)
    @forum = Gws::Discussion::Forum.find(params[:forum_id])
  end

  def set_crumbs
    @crumbs << [t('modules.gws/discussion'), gws_discussion_forums_path]
    @crumbs << [@forum.name, gws_discussion_forum_topics_path]
    @crumbs << ["TODO", gws_discussion_forum_todos_path]
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

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.name = "[#{@forum.name}]"
    #@item.member_ids = @forum.member_ids
    #@item.member_custom_group_ids = @forum.member_custom_group_ids
    @item.member_ids = @forum.discussion_member_ids
  end

  def print
    @items = Gws::Schedule::Todo.
      site(@cur_site).
      discussion_forum(@forum).
      allow(:read, @cur_user, site: @cur_site).
      without_deleted.
      search(params[:s])

    render layout: 'ss/print'
  end

  def events
    @start_at = params[:s][:start].to_date
    @end_at = params[:s][:end].to_date

    @todos = Gws::Schedule::Todo.
      site(@cur_site).
      discussion_forum(@forum).
      member(@cur_user).
      without_deleted.
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
end
