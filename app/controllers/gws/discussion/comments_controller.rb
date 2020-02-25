class Gws::Discussion::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Discussion::Post

  before_action :set_forum
  before_action :set_topic
  before_action :set_crumbs
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :copy]

  navi_view "gws/discussion/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, topic_id: @topic.id, parent_id: @topic.id }
  end

  def pre_params
    @skip_default_group = true
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

  def set_topic
    @topic = Gws::Discussion::Topic.find(params[:topic_id])
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_topics_path ]
    @crumbs << [ @topic.name, gws_discussion_forum_topic_comments_path ]
  end

  public

  def index
  end

  def show
    redirect_to action: :index
  end

  def edit
    raise "403" if @topic.permanently?
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
    raise "403" if @topic.permanently?
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def delete
    raise "403" if @topic.permanently?
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" if @topic.permanently?
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def reply
    raise "403" unless @topic.permit_comment?
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
    @comment = @model.new get_params

    @comment = Gws::Discussion::Post.new get_params
    @comment.topic_id = @topic.id
    @comment.parent_id = @topic.id
    @comment.forum_id = @forum.id
    @comment.name = @topic.name
    result = @comment.save
    @item = @comment

    if result
      @comment.save_notify_message(@cur_site, @cur_user)
      render_create true, location: { action: :index }, render: { file: :index }
    else
      render_create false, location: { action: :index }, render: { file: :index }
    end
  end
end
