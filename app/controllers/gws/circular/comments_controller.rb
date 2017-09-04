class Gws::Circular::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Post

  before_action :set_parent

  private

  def fix_params
    {
        cur_user: @cur_user,
        cur_site: @cur_site,
        topic_id: params[:topic_id],
        parent_id: params[:parent_id],
        user_ids: [@cur_user.id]
    }
  end

  def pre_params
    { name: "Re: #{@topic.name}" }
  end

  def set_parent
    @topic = Gws::Circular::Topic.find params[:topic_id]
  end

  def set_crumbs
    @crumbs << ['回覧板', gws_circular_topics_path]
  end

  public

  def index
    redirect_to gws_circular_topic_path(id: @topic.id)
  end

  def show
    redirect_to gws_circular_topic_path(id: @topic.id)
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.valid? && @item.topic.save && @item.save
  end
end
