class Gws::Monitor::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Memo::NotificationFilter

  model Gws::Monitor::Post

  before_action :set_category
  before_action :set_topic_and_parent

  before_action :check_creatable, only: %i[new create]
  before_action :check_updatable, only: %i[edit update]
  before_action :check_destroyable, only: %i[delete destroy]

  navi_view "gws/monitor/main/navi"

  private

  def set_crumbs
    set_category
    @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_main_path]
    if @category.present?
      @crumbs << [@category.name, gws_monitor_topics_path]
    end
    if params[:topic_id].present?
      @crumbs << [t('gws/monitor.tabs.unanswer'), action: :index]
    elsif params[:answer_id].present?
      @crumbs << [t('gws/monitor.tabs.answer'), action: :index]
    elsif params[:admin_id].present?
      @crumbs << [t('gws/monitor.tabs.admin'), action: :index]
    end
  end

  def set_category
    if params[:category].present? && params[:category] != '-'
      @category ||= Gws::Monitor::Category.site(@cur_site).where(id: params[:category]).first
    end
  end

  def fix_params
    if params[:topic_id].present?
      { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:topic_id], parent_id: params[:parent_id] }
    elsif params[:answer_id].present?
      { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:answer_id], parent_id: params[:parent_id] }
    elsif params[:admin_id].present?
      { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:admin_id], parent_id: params[:parent_id] }
    end

  end

  def pre_params
    { name: "Re: #{@parent.name}" }
  end

  def set_topic_and_parent
    topic_id = params[:topic_id]
    topic_id ||= params[:answer_id]
    topic_id ||= params[:admin_id]

    @topic ||= Gws::Monitor::Topic.site(@cur_site).topic.find(topic_id)
    @parent ||= @model.site(@cur_site).find(params[:parent_id])
  end

  def check_creatable
    creatable = false
    creatable = true if @topic.allowed?(:edit, @cur_user, site: @cur_site)
    creatable = true if @topic.permit_comment? && @topic.public? && @topic.article_state == 'open' && @topic.attended?(@cur_group)
    raise '403' unless creatable
  end

  def check_updatable
    updatable = false
    updatable = true if @topic.allowed?(:edit, @cur_user, site: @cur_site)
    updatable = true if @topic.attended?(@cur_group) && @item.user_group_id == @cur_group.id
    raise '403' unless updatable
  end

  def check_destroyable
    destroyable = false
    destroyable = true if @topic.allowed?(:delete, @cur_user, site: @cur_site)
    destroyable = true if @topic.attended?(@cur_group) && @item.user_group_id == @cur_group.id
    raise '403' unless destroyable
  end

  def get_show_path
    if params[:topic_id].present?
      gws_monitor_topic_path(id: @topic)
    elsif params[:answer_id].present?
      gws_monitor_answer_path(id: @topic)
    elsif params[:admin_id].present?
      gws_monitor_admin_path(id: @topic)
    end
  end

  public

  def index
    redirect_to get_show_path
  end

  def show
    redirect_to get_show_path
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    @item = @model.new get_params
    result = @item.save

    if result
      case params[:commit]
      when I18n.t("gws/monitor.links.comment")
        @topic.answer_state_hash[@cur_group.id.to_s] = "answered"
        @topic.save
      when I18n.t("gws/monitor.links.question_not_applicable")
        @topic.answer_state_hash[@cur_group.id.to_s] = "question_not_applicable"
        @topic.save
      end
    end

    render_create result, {location: get_show_path}
  end

  def edit
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    render_update @item.update, {location: get_show_path}
  end

  def delete
    render
  end

  def destroy
    render_destroy @item.destroy, {location: get_show_path}
  end
end
