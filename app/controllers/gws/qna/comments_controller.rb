class Gws::Qna::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Qna::Post

  before_action :set_category
  before_action :set_parent

  private

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [t("modules.gws/qna"), gws_qna_topics_path]
      @crumbs << [@category.name, gws_qna_category_topics_path]
    else
      @crumbs << [t("modules.gws/qna"), gws_qna_topics_path]
    end
  end

  def set_category
    if params[:category].present?
      @category ||= Gws::Qna::Category.site(@cur_site).where(id: params[:category]).first
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
      redirect_to gws_qna_category_topic_path(id: @topic.id)
    else
      redirect_to gws_qna_topic_path(id: @topic.id)
    end
  end

  def show
    if @category.present?
      redirect_to gws_qna_category_topic_path(id: @topic.id)
    else
      redirect_to gws_qna_topic_path(id: @topic.id)
    end
  end
end
