class Gws::Discussion::Thread::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Discussion::BaseFilter

  model Gws::Discussion::Post

  before_action :set_topic
  before_action :set_crumbs
  before_action :set_item, only: [:edit, :update, :delete, :destroy]
  before_action :comment_disallowed

  helper_method :index_path

  navi_view "gws/discussion/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, topic_id: @topic.id, parent_id: @topic.id }
  end

  def pre_params
    @skip_default_group = true
    super
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_portal_path ]
    @crumbs << [ @topic.name, { action: :index } ]
  end

  def set_topic
    @topic = Gws::Discussion::Topic.find(params[:topic_id])
  end

  def index_path
    url_for(action: :index)
  end

  def crud_redirect_url
    index_path
  end

  def comment_disallowed
    case params[:action].to_s
    when "edit", "update", "delete", "destroy"
      raise "403" if @topic.permanently?
    when "reply"
      raise "403" if !@topic.permit_comment?
    end
  end

  public

  def index
  end

  def reply
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
    @comment = @model.new get_params

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
