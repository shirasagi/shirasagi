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
    { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:topic_id], parent_id: params[:parent_id] }
  end

  def pre_params
    { name: "Re: #{@parent.name}" }
  end

  def set_parent
    @topic  = @model.find params[:topic_id]
    @parent = @model.find params[:parent_id]
  end

  public

  def index
    if @category.present?
      redirect_to gws_monitor_category_topic_path(id: @topic.id)
    else
      redirect_to gws_monitor_topic_path(id: @topic.id)
    end
  end

  def show
    if @category.present?
      redirect_to gws_monitor_category_topic_path(id: @topic.id)
    else
      redirect_to gws_monitor_topic_path(id: @topic.id)
    end
  end

  def create
    @item = @model.new get_params
    if params[:commit] == I18n.t("gws/monitor.links.comment")
      @item.parent.state_of_the_answers_hash[@cur_group.id.to_s] = "answered"
    else
      @item.parent.state_of_the_answers_hash[@cur_group.id.to_s] = "question_not_applicable"
    end
    @item.parent.save
    render_create @item.save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if params[:commit] == I18n.t("gws/monitor.links.comment")
      @item.parent.state_of_the_answers_hash[@cur_group.id.to_s] = "answered"
    else
      @item.parent.state_of_the_answers_hash[@cur_group.id.to_s] = "question_not_applicable"
    end
    @item.parent.save
    render_update @item.update
  end
end

