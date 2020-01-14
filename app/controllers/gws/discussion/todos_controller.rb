class Gws::Discussion::TodosController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::TodoFilter
  include Gws::Schedule::Todo::NotificationFilter

  model Gws::Schedule::Todo

  before_action :set_forum
  before_action :set_crumbs
  before_action :set_addons

  navi_view "gws/discussion/main/navi"

  private

  def set_forum
    raise "403" unless Gws::Discussion::Forum.allowed?(:read, @cur_user, site: @cur_site)
    @forum = Gws::Discussion::Forum.find(params[:forum_id])

    raise "404" unless @forum.allowed?(:read, @cur_user, site: @cur_site) || @forum.member?(@cur_user)
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_topics_path ]
    @crumbs << [ t('modules.gws/schedule/todo'), gws_discussion_forum_todos_path ]
  end

  def pre_params
    @skip_default_group = true
    {
      start_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00'),
      member_ids: params[:member_ids].presence || [@cur_user.id]
    }
  end

  def fix_params
    set_forum
    { cur_user: @cur_user, cur_site: @cur_site, in_discussion_forum: true, discussion_forum: @forum }
  end

  def set_addons
    @addons ||= begin
      addons = @model.addons
      addons = addons.reject do |addon|
        [ Gws::Addon::Schedule::Todo::Category, Gws::Addon::Discussion::Todo ].include?(addon.klass)
      end
      addons
    end
  end

  def set_items
    or_conds = @model.member_conditions(@cur_user)
    or_conds += @model.readable_conditions(@cur_user, site: @cur_site)
    or_conds << @model.allow_condition(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      discussion_forum(@forum).
      where("$and" =>[ "$or" => or_conds ]).
      without_deleted.
      search(params[:s])
  end

  public

  def index
    @items = @model.none
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.name = "[#{@forum.name}]"
    #@item.member_ids = @forum.member_ids
    #@item.member_custom_group_ids = @forum.member_custom_group_ids
    @item.member_ids = @forum.overall_members.pluck(:id)
  end

  def print
    set_items
    render layout: 'ss/print'
  end

  def events
    @start_at = params[:s][:start].to_date
    @end_at = params[:s][:end].to_date

    set_items
    @todos = @items.map do |todo|
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
