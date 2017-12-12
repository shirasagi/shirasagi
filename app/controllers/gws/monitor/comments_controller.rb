class Gws::Monitor::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Post

  before_action :set_category
  before_action :set_parent

  private

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [@category.name, gws_monitor_category_topics_path]
    else
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
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
    if @category.present?
      if params[:topic_id].present?
        redirect_to gws_monitor_category_topic_path(id: @topic.id)
      elsif params[:answer_id].present?
        redirect_to gws_monitor_category_answer_path(id: @topic.id)
      elsif params[:admin_id].present?
        redirect_to gws_monitor_category_admin_path(id: @topic.id)
      end
    else
      if params[:topic_id].present?
        redirect_to gws_monitor_topic_path(id: @topic.id)
      elsif params[:answer_id].present?
        redirect_to gws_monitor_answer_path(id: @topic.id)
      elsif params[:admin_id].present?
        redirect_to gws_monitor_admin_path(id: @topic.id)
      end
    end
  end

  def show
    if @category.present?
      if params[:topic_id].present?
        redirect_to gws_monitor_category_topic_path(id: @topic.id)
      elsif params[:answer_id].present?
        redirect_to gws_monitor_category_answer_path(id: @topic.id)
      elsif params[:admin_id].present?
        redirect_to gws_monitor_category_admin_path(id: @topic.id)
      end
    else
      if params[:topic_id].present?
        redirect_to gws_monitor_topic_path(id: @topic.id)
      elsif params[:answer_id].present?
        redirect_to gws_monitor_answer_path(id: @topic.id)
      elsif params[:admin_id].present?
        redirect_to gws_monitor_admin_path(id: @topic.id)
      end
    end
  end

  def create
    @item = @model.new get_params
    case params[:commit]
    when I18n.t("gws/monitor.links.comment")
      @item.parent.state_of_the_answers_hash[@cur_group.id.to_s] = "answered"
      @item.parent.save
    when I18n.t("gws/monitor.links.question_not_applicable")
      @item.parent.state_of_the_answers_hash[@cur_group.id.to_s] = "question_not_applicable"
      @item.parent.save
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

