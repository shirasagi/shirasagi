class Gws::QuestionManagementController < ApplicationController
  include Gws::BaseFilter

  navi_view "gws/qna/main/navi"

  private

  def set_crumbs
    @crumbs << [t("gws.question_management"), action: :index]
  end

  public

  def index
    @faq_items = Gws::Faq::Topic.topic.
      and_public.
      readable(@cur_user, site: @cur_site).
      order_by(descendants_updated: -1).
      limit(5)

    @qna_items = Gws::Qna::Topic.topic.
      and_public.
      readable(@cur_user, site: @cur_site).
      order_by(descendants_updated: -1).
      limit(5)
  end
end
