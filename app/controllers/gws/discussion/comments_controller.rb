class Gws::Discussion::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Discussion::Post

  before_action :set_forum
  before_action :set_topic
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :copy]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, topic_id: @topic.id, parent_id: @topic.id }
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

  def set_topic
    @topic = Gws::Discussion::Topic.find(params[:topic_id])
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/discussion'), gws_discussion_forums_path]
  end

  public

  def index
    #
  end

  def show
    redirect_to action: :index
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update, location: { action: :index }
  end

  def reply
    @comment = @model.new get_params

    @comment = Gws::Discussion::Post.new get_params
    @comment.topic_id = @topic.id
    @comment.parent_id = @topic.id
    @comment.forum_id = @forum.id
    @comment.name = @topic.name
    render_create @comment.save, location: { action: :index }, render: { file: :index }
  end
end
