class Guide::Apis::QuestionsController < ApplicationController
  include Cms::ApiFilter

  model Guide::Question

  def index
    @multi = params[:single].blank?
    @node = Cms::Node.find(params[:nid])
    @id = params[:id].to_i

    @items = @model.site(@cur_site).
      node(@node).
      ne(id: @id).
      where(referenced_question_ids: []).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
