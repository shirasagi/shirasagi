class Gws::Discussion::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Discussion::BaseFilter

  helper Gws::Schedule::PlanHelper
  model Gws::Discussion::Topic

  before_action :set_crumbs

  helper_method :topic_options

  navi_view "gws/discussion/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, parent_id: @forum.id }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_portal_path ]
  end

  def set_items
    set_topics
    set_recent_items
    set_todo
    set_bookmarks
  end

  def set_topics
    @items = @forum.children.reorder(order: 1, created: -1).
      page(params[:page]).per(5)
  end

  def set_recent_items
    @recent_items = @forum.children.
      where(:descendants_updated.gt => (Time.zone.now - @cur_site.discussion_new_days.day)).
      reorder(descendants_updated: -1).
      limit(@cur_site.discussion_recent_limit)
  end

  def set_todo
    common_todo_criteria = Gws::Schedule::Todo.
      site(@cur_site).
      discussion_forum(@forum).
      where(:todo_state.ne => 'finished').
      without_deleted.
      limit(@cur_site.discussion_todo_limit)

    @todos = common_todo_criteria.member(@cur_user)

    @manageable_todos = common_todo_criteria.
      readable_or_manageable(@cur_user, site: @cur_site).
      not_member(@cur_user)
  end

  def set_bookmarks
    @bookmarks = @bookmarker.bookmarks.values.take(@cur_site.discussion_bookmark_limit)
  end

  def topic_options
    @items.pluck(:name, :id)
  end

  public

  def index
    set_items
  end

  def search
    set_items

    @comments = Gws::Discussion::Post.site(@cur_site).
      where(forum_id: @forum.id).
      search(params[:s]).
      reorder(order: 1, updated: -1).
      page(params[:page]).per(50)
  end

  def reply
    raise "403" unless Gws::Discussion::Post.allowed?(:edit, @cur_user, site: @cur_site)

    set_items
    @topic = Gws::Discussion::Topic.find(params[:id])
    raise "403" unless @topic.permit_comment?

    @comment = Gws::Discussion::Post.new get_params
    @comment.topic_id = @topic.id
    @comment.parent_id = @topic.id
    @comment.forum_id = @forum.id
    @comment.name = @topic.name

    if @comment.save
      @comment.save_notify_message(@cur_site, @cur_user)
      render_create true, location: { action: :index }, render: { template: "index" }
    else
      render_create false, location: { action: :index }, render: { template: "index" }
    end
  end
end
