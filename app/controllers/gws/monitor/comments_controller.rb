class Gws::Monitor::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Post

  before_action :set_category
  before_action :set_parent

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
    if params[:category].present?
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

  def set_parent
    if params[:topic_id].present?
      @topic  = @model.find params[:topic_id]
    elsif params[:answer_id].present?
      @topic  = @model.find params[:answer_id]
    elsif params[:admin_id].present?
      @topic  = @model.find params[:admin_id]
    end
    @parent = @model.find params[:parent_id]
  end

  public

  def index
    if params[:topic_id].present?
      redirect_to gws_monitor_topic_path(id: @topic.id)
    elsif params[:answer_id].present?
      redirect_to gws_monitor_answer_path(id: @topic.id)
    elsif params[:admin_id].present?
      redirect_to gws_monitor_admin_path(id: @topic.id)
    end
  end

  def show
    if params[:topic_id].present?
      redirect_to gws_monitor_topic_path(id: @topic.id)
    elsif params[:answer_id].present?
      redirect_to gws_monitor_answer_path(id: @topic.id)
    elsif params[:admin_id].present?
      redirect_to gws_monitor_admin_path(id: @topic.id)
    end
  end

  def create
    @item = @model.new get_params
    case params[:commit]
    when I18n.t("gws/monitor.links.comment")
      @item.topic.answer_state_hash[@cur_group.id.to_s] = "answered"
      @item.topic.save
    when I18n.t("gws/monitor.links.question_not_applicable")
      @item.topic.answer_state_hash[@cur_group.id.to_s] = "question_not_applicable"
      @item.topic.save
    end

    if params[:topic_id].present?
      controller = "gws/monitor/topics"
      id = params[:topic_id]
    elsif params[:answer_id].present?
      controller = "gws/monitor/answers"
      id = params[:answer_id]
    elsif params[:admin_id].present?
      controller = "gws/monitor/admins"
      id = params[:admin_id]
    end

    render_create @item.save, {location: {controller: controller, action: 'show', id: id}}
  end

  def edit
    raise "403" unless @item.readable?(@cur_user, site: @cur_site)
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    if params[:topic_id].present?
      controller = "gws/monitor/topics"
      id = params[:topic_id]
    elsif params[:answer_id].present?
      controller = "gws/monitor/answers"
      id = params[:answer_id]
    elsif params[:admin_id].present?
      controller = "gws/monitor/admins"
      id = params[:admin_id]
    end

    render_update @item.update, {location: {controller: controller, action: 'show', id: id}}
  end

  def delete
    raise "403" unless @item.readable?(@cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @item.readable?(@cur_user, site: @cur_site)
    render_destroy @item.destroy
  end
end
