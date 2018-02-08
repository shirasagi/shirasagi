class Gws::Qna::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Qna::BaseFilter
  include Gws::Memo::NotificationFilter

  model Gws::Qna::Post

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, topic_id: params[:topic_id], parent_id: params[:parent_id] }
  end

  def pre_params
    { name: "Re: #{@parent.name}" }
  end

  public

  def index
    redirect_to gws_qna_topic_path(id: @topic.id)
  end

  def show
    redirect_to gws_qna_topic_path(id: @topic.id)
  end
end
