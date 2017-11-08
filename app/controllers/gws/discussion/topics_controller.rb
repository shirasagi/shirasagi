class Gws::Discussion::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  helper Gws::Schedule::PlanHelper
  model Gws::Discussion::Topic

  before_action :set_forum
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :comments, :reply, :copy]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, parent_id: @forum.id }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/discussion'), gws_discussion_forums_path]
  end

  def set_forum
    @forum = Gws::Discussion::Forum.find(params[:forum_id])

    if @forum.state == "closed"
      permitted = @forum.allowed?(:read, @cur_user, site: @cur_site)
    else
      permitted = @forum.readable?(@cur_user, site: @cur_site)
    end

    raise "403" unless permitted
  end

  def set_items
    @items = @forum.children.reorder(created: 1).
      page(params[:page]).per(5)

    @todos = Gws::Schedule::Todo.
      site(@cur_site).
      discussion_forum(@forum).
      allow(:read, @cur_user, site: @cur_site).
      where(todo_state: 'unfinished').
      active().
      limit(10)

    @recent_items = @forum.children.
      where(:descendants_updated.gt => (Time.zone.now - @cur_site.discussion_new_days.day)).
      reorder(descendants_updated: -1).
      limit(10)
  end

  public

  def index
    set_items
  end

  def all
    @items = @forum.children.reorder(created: 1).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def comments
    render
  end

  def reply
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    set_items
    @topic = Gws::Discussion::Topic.find(params[:id])
    @comment = Gws::Discussion::Post.new get_params
    @comment.topic_id = @topic.id
    @comment.parent_id = @topic.id
    @comment.forum_id = @forum.id
    @comment.name = @topic.name
    render_create @comment.save, location: { action: :index }, render: { file: :index }
  end

  def copy
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}"
      return
    end

    @item.attributes = get_params
    if @item.valid?
      item = @item.save_clone(@topic)
      item.attributes = get_params
      render_create true, render: { file: :copy }
    else
      render_create false, render: { file: :copy }
    end
  end
end
