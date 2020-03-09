class Gws::Discussion::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  helper Gws::Schedule::PlanHelper
  model Gws::Discussion::Topic

  before_action :set_forum
  before_action :set_crumbs
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :comments, :reply, :copy]

  navi_view "gws/discussion/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, parent_id: @forum.id }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_topics_path ]
  end

  def pre_params
    #@skip_default_group = true
    super
  end

  def set_forum
    raise "403" unless Gws::Discussion::Forum.allowed?(:read, @cur_user, site: @cur_site)
    @forum = Gws::Discussion::Forum.find(params[:forum_id])

    if @forum.state == "closed"
      permitted = @forum.allowed?(:read, @cur_user, site: @cur_site)
    else
      permitted = @forum.allowed?(:read, @cur_user, site: @cur_site) || @forum.member?(@cur_user)
    end

    raise "403" unless permitted
  end

  def set_items
    @items = @forum.children.reorder(order: 1, created: -1).
      page(params[:page]).per(5)

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

    @recent_items = @forum.children.
      where(:descendants_updated.gt => (Time.zone.now - @cur_site.discussion_new_days.day)).
      reorder(descendants_updated: -1).
      limit(@cur_site.discussion_recent_limit)
  end

  public

  def index
    set_items
  end

  def show
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.save
      @item.save_notify_message(@cur_site, @cur_user)
      render_create true
    else
      render_create false
    end
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def all
    @items = @model.in(id: @forum.children.pluck(:id)).
      reorder(order: 1, created: 1).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def comments
    render
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
    result = @comment.save

    if result
      @item = @comment
      @comment.save_notify_message(@cur_site, @cur_user)
      render_create true, location: { action: :index }, render: { file: :index }
    else
      @item = @topic
      render_create false, location: { action: :index }, render: { file: :index }
    end
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
      render_create true, location: { action: :index }, render: { file: :copy }
    else
      render_create false, location: { action: :index }, render: { file: :copy }
    end
  end
end
