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

  def set_forum
    @forum ||= begin
      raise "403" unless Gws::Discussion::Forum.allowed?(:read, @cur_user, site: @cur_site)
      forum = Gws::Discussion::Forum.site(@cur_site).find(params[:forum_id])
      raise "404" unless forum.allowed?(:read, @cur_user, site: @cur_site) || forum.member_include?(@cur_user)
      forum
    end
  end

  def set_topic
    @topic ||= begin
      set_forum
      topic = Gws::Discussion::Topic.site(@cur_site).find(params[:topic_id])
      raise "404" if topic.parent_id != @forum.id
      topic
    end
  end

  def set_items
    @items ||= begin
      set_topic
      @topic.descendants
    end
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

  def download_attachment
    if params[:topic_id] == params[:id]
      set_items
      @item = @topic
    else
      set_item
    end

    files = @item.files
    if files.blank?
      redirect_to({ action: :show }, { notice: t("gws/workflow.notice.no_files") })
      return
    end

    filename = "discussion_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    name = "#{@item.name}.zip"
    zip = Gws::Compressor.new(@cur_user, model: SS::File, items: files, filename: filename, name: name)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename, name: name)

    if zip.deley_download?
      job = Gws::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :index }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save
      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end
end
